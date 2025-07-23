variable "instance_type" {
  description = "The type of EC2 instance for Cassandra"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "The AMI ID for the Cassandra EC2 instance"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The key pair name to access the Cassandra EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID where Cassandra will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for Cassandra"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Cassandra cluster"
  type        = string
  default     = "Ryan EC2 Cluster"
}

variable "created_by" {
  description = "The name or identifier of who created the resources"
  type        = string
  default     = "terraform"
}
