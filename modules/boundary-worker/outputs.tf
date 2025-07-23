output "instance_id" {
  description = "ID of the Boundary worker instance"
  value       = aws_instance.boundary_worker.id
}

output "public_ip" {
  description = "Public IP address of the Boundary worker"
  value       = aws_instance.boundary_worker.public_ip
}

output "private_ip" {
  description = "Private IP address of the Boundary worker"
  value       = aws_instance.boundary_worker.private_ip
}

output "worker_endpoint" {
  description = "Boundary worker endpoint"
  value       = "${aws_instance.boundary_worker.public_ip}:9202"
}

output "hcp_cluster_id" {
  description = "HCP Boundary cluster ID"
  value       = var.boundary_hcp_cluster_id
}
