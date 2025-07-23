# General Variables
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "created_by" {
  description = "The name or identifier of who created the resources"
  type        = string
  default     = "terraform"
}

# Networking Variables
variable "vpc_id" {
  description = "Existing VPC ID to deploy resources into (if not provided, a new VPC will be created)"
  type        = string
  default     = ""
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (only used if vpc_id is not provided)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to instances. If empty, no SSH access will be allowed."
  type        = list(string)
  default     = []
}

variable "enable_internal_ssh" {
  description = "Enable SSH access to Cassandra from the Boundary worker network only"
  type        = bool
  default     = false
}

# General Variables
variable "key_name" {
  description = "The key pair name to access the EC2 instances"
  type        = string
}

# Boundary Worker Variables
variable "boundary_worker_instance_type" {
  description = "The instance type for the Boundary worker EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "boundary_worker_ami_id" {
  description = "The AMI ID for the Boundary worker EC2 instance (leave empty for latest Ubuntu)"
  type        = string
  default     = ""
}

variable "boundary_hcp_cluster_id" {
  description = "The HCP Boundary cluster ID for registration"
  type        = string
}

variable "controller_generated_activation_token" {
  description = "The controller-generated activation token for the Boundary worker"
  type        = string
  sensitive   = true
}

variable "boundary_version" {
  description = "The version of Boundary Enterprise to install"
  type        = string
  default     = "0.19.3"
}

# Cassandra Variables
variable "cassandra_instance_type" {
  description = "The instance type for the Cassandra EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "cassandra_ami_id" {
  description = "The AMI ID for the Cassandra EC2 instance (leave empty for latest Ubuntu)"
  type        = string
  default     = ""
}

variable "cassandra_cluster_name" {
  description = "The name of the Cassandra cluster"
  type        = string
  default     = "Cassandra EC2 Cluster"
}
