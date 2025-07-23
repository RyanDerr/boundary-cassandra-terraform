# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC (existing or newly created)"
  value       = module.networking.vpc_id
}

output "vpc_created" {
  description = "Whether a new VPC was created or existing one was used"
  value       = module.networking.vpc_created
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.networking.private_subnet_id
}

# Boundary Worker Outputs
output "boundary_worker_instance_id" {
  description = "ID of the Boundary worker instance"
  value       = module.boundary_worker.instance_id
}

output "boundary_worker_public_ip" {
  description = "Public IP address of the Boundary worker"
  value       = module.boundary_worker.public_ip
}

output "boundary_worker_private_ip" {
  description = "Private IP address of the Boundary worker"
  value       = module.boundary_worker.private_ip
}

output "boundary_worker_endpoint" {
  description = "Boundary worker endpoint"
  value       = module.boundary_worker.worker_endpoint
}

# Cassandra Outputs
output "cassandra_instance_id" {
  description = "ID of the Cassandra instance"
  value       = module.cassandra.instance_id
}

output "cassandra_private_ip" {
  description = "Private IP address of the Cassandra instance"
  value       = module.cassandra.private_ip
}

output "cassandra_connection_info" {
  description = "Connection information for Cassandra"
  value       = module.cassandra.cassandra_connection_info
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    boundary_worker = {
      public_ip  = module.boundary_worker.public_ip
      private_ip = module.boundary_worker.private_ip
      endpoint   = module.boundary_worker.worker_endpoint
    }
    cassandra = {
      private_ip = module.cassandra.private_ip
      port       = "9042"
      cluster    = var.cassandra_cluster_name
    }
    network = {
      vpc_id            = module.networking.vpc_id
      public_subnet_id  = module.networking.public_subnet_id
      private_subnet_id = module.networking.private_subnet_id
    }
  }
}
