# Data source to get existing VPC if provided
data "aws_vpc" "existing" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

# Data source to get existing internet gateway if using existing VPC
data "aws_internet_gateway" "existing" {
  count = var.vpc_id != "" ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# VPC (only create if vpc_id is not provided)
resource "aws_vpc" "main" {
  count                = var.vpc_id == "" ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "boundary-cassandra-vpc"
    CreatedBy = var.created_by
  }
}

# Internet Gateway (only create if vpc_id is not provided)
resource "aws_internet_gateway" "main" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name      = "boundary-cassandra-igw"
    CreatedBy = var.created_by
  }
}

# Local values to determine which VPC and IGW to use
locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : aws_vpc.main[0].id
  igw_id = var.vpc_id != "" ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id
}

# Public Subnet (for Boundary Worker)
resource "aws_subnet" "public" {
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name      = "boundary-public-subnet"
    CreatedBy = var.created_by
  }
}

# Private Subnet (for Cassandra)
resource "aws_subnet" "private" {
  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name      = "cassandra-private-subnet"
    CreatedBy = var.created_by
  }
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "cassandra-nat-eip"
    CreatedBy = var.created_by
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name      = "cassandra-nat-gateway"
    CreatedBy = var.created_by
  }

  depends_on = [
    aws_internet_gateway.main,
    data.aws_internet_gateway.existing
  ]
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name      = "boundary-public-rt"
    CreatedBy = var.created_by
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name      = "cassandra-private-rt"
    CreatedBy = var.created_by
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "boundary_worker" {
  name        = "boundary-worker-sg"
  description = "Security group for Boundary worker"
  vpc_id      = local.vpc_id

  ingress {
    description = "Boundary worker port"
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Conditional SSH access - only create if ssh_allowed_cidrs is not empty
  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "boundary-worker-sg"
    CreatedBy = var.created_by
  }
}

# Security Group for Cassandra
resource "aws_security_group" "cassandra" {
  name        = "cassandra-sg"
  description = "Security group for Cassandra database"
  vpc_id      = local.vpc_id

  ingress {
    description     = "Cassandra CQL port from Boundary worker"
    from_port       = 9042
    to_port         = 9042
    protocol        = "tcp"
    security_groups = [aws_security_group.boundary_worker.id]
  }

  # Conditional SSH access from Boundary worker network only
  dynamic "ingress" {
    for_each = var.enable_internal_ssh ? [1] : []
    content {
      description     = "SSH from Boundary worker network"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [aws_security_group.boundary_worker.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "cassandra-sg"
    CreatedBy = var.created_by
  }
}
