output "instance_id" {
  description = "Provisioned EC2 instance ID"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP of CloudShift Store"
  value       = module.compute.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS of CloudShift Store"
  value       = module.compute.instance_public_dns
}

output "app_url" {
  description = "CloudShift Store URL"
  value       = module.compute.app_url
}