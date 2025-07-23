output "vpc_id" {
  description = "ID of the VPC (existing or newly created)"
  value       = local.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "boundary_worker_security_group_id" {
  description = "ID of the Boundary worker security group"
  value       = aws_security_group.boundary_worker.id
}

output "cassandra_security_group_id" {
  description = "ID of the Cassandra security group"
  value       = aws_security_group.cassandra.id
}

output "vpc_created" {
  description = "Whether a new VPC was created or existing one was used"
  value       = var.vpc_id == "" ? true : false
}
