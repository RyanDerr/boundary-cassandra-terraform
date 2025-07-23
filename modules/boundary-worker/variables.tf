variable "instance_type" {
  description = "The instance type for the Boundary worker EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "The AMI ID for the Boundary worker EC2 instance"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The key pair name to access the Boundary worker EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where the Boundary worker will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the Boundary worker"
  type        = string
}

variable "boundary_hcp_cluster_id" {
  description = "The HCP Boundary cluster ID"
  type        = string
}

variable "controller_generated_activation_token" {
  description = "The controller-generated activation token for the Boundary worker"
  type        = string
  sensitive   = true
}

variable "worker_tags" {
  description = "Custom tags for the Boundary worker"
  type        = map(list(string))
  default = {
    type = ["worker", "linux", "ec2", "upstream"]
  }
}

variable "created_by" {
  description = "The name or identifier of who created the resources"
  type        = string
  default     = "terraform"
}

variable "boundary_version" {
  description = "The version of Boundary Enterprise to install"
  type        = string
  default     = "0.19.3"
}
