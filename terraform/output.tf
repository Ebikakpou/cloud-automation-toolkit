

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
    description = "Open this in a browser once the instance finishes booting (~1-2 minutes)"
    value       = "http://${aws_instance.cloudshift_store.public_ip}"
}
