output "instance_id" {
  description = "The provisioned EC2 instance's ID"
  value       = aws_instance.cloudshift_store.id
}

output "instance_public_ip" {
  description = "Public IP address of the CloudShift Store instance"
  value       = aws_instance.cloudshift_store.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the CloudShift Store instance"
  value       = aws_instance.cloudshift_store.public_dns
}

output "app_url" {
  description = "URL to access the CloudShift Store application"
  value       = "http://${aws_instance.cloudshift_store.public_ip}"
}

output "prometheus_url" {
  description = "URL to access the Prometheus monitoring dashboard"
  value       = "http://${aws_instance.cloudshift_store.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access the Grafana monitoring dashboard"
  value       = "http://${aws_instance.cloudshift_store.public_ip}:3000"
}

output "docker_services" {
  description = "URLs for all Docker Compose services automatically started on the EC2 instance"
  value = {
    cloudshift_store = "http://${aws_instance.cloudshift_store.public_ip}:80"
    prometheus       = "http://${aws_instance.cloudshift_store.public_ip}:9090"
    grafana          = "http://${aws_instance.cloudshift_store.public_ip}:3000"
  }
}