# Data source to get available AZs if not specified
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for computed configurations
locals {
  # Use provided availability zone or default to first available
  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
}

# Networking Module - Creates VPC, subnets, and security groups
module "networking" {
  source = "./modules/networking"

  vpc_id              = var.vpc_id
  availability_zone   = local.availability_zone
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  ssh_allowed_cidrs   = var.ssh_allowed_cidrs
  enable_internal_ssh = var.enable_internal_ssh
  created_by          = var.created_by
}

# Boundary Worker Module - Creates EC2 instance for Boundary worker
module "boundary_worker" {
  source = "./modules/boundary-worker"

  instance_type                         = var.boundary_worker_instance_type
  key_name                              = var.key_name
  subnet_id                             = module.networking.public_subnet_id
  security_group_id                     = module.networking.boundary_worker_security_group_id
  boundary_hcp_cluster_id               = var.boundary_hcp_cluster_id
  controller_generated_activation_token = var.controller_generated_activation_token
  boundary_version                      = var.boundary_version
  created_by                            = var.created_by

  worker_tags = {
    type        = ["worker", "linux", "ec2", "managed", "cassandra-access", "upstream"]
    environment = [var.environment]
  }

  depends_on = [module.networking]
}

# Cassandra Module - Creates EC2 instance for Cassandra database
module "cassandra" {
  source = "./modules/cassandra"

  instance_type     = var.cassandra_instance_type
  key_name          = var.key_name
  subnet_id         = module.networking.private_subnet_id
  security_group_id = module.networking.cassandra_security_group_id
  cluster_name      = var.cassandra_cluster_name
  created_by        = var.created_by

  depends_on = [module.networking]
}

# Wait 2 minutes after resource creation to give time for Cassandra to initialize and Boundary worker to register
resource "time_sleep" "wait_for_infrastructure" {
  create_duration = "120s"

  depends_on = [module.networking, module.boundary_worker, module.cassandra]
}

# Random ID for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}
