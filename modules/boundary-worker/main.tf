# Data source to get the latest Ubuntu AMI if none specified
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Boundary Worker EC2 Instance
resource "aws_instance" "boundary_worker" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/user-data.sh", {
    boundary_hcp_cluster_id               = var.boundary_hcp_cluster_id
    controller_generated_activation_token = var.controller_generated_activation_token
    boundary_version                      = var.boundary_version
    worker_tags                           = jsonencode(local.merged_worker_tags)
  })

  tags = {
    Name      = "boundary-worker"
    Type      = "boundary-worker"
    CreatedBy = var.created_by
  }
}
