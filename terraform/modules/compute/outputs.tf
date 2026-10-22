output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cloudshift_store.id
}

output "instance_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.cloudshift_store.public_ip
}

output "instance_public_dns" {
  description = "EC2 public DNS name"
  value       = aws_instance.cloudshift_store.public_dns
}

output "app_url" {
  description = "CloudShift Store HTTP URL"
  value       = "http://${aws_instance.cloudshift_store.public_ip}"
}