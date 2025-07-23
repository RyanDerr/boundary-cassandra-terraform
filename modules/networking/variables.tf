variable "vpc_id" {
  description = "Existing VPC ID to use (if empty, a new VPC will be created)"
  type        = string
  default     = ""
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (only used if creating new VPC)"
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

variable "created_by" {
  description = "The name or identifier of who created the resources"
  type        = string
  default     = "terraform"
}
