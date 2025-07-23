output "instance_id" {
  description = "ID of the Cassandra instance"
  value       = aws_instance.cassandra.id
}

output "private_ip" {
  description = "Private IP address of the Cassandra instance"
  value       = aws_instance.cassandra.private_ip
}

output "cassandra_connection_info" {
  description = "Connection information for Cassandra"
  value       = "Cassandra is running on ${aws_instance.cassandra.private_ip}:9042"
}
