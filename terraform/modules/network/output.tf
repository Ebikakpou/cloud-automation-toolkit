output "vpc_id" {
  description = "ID of the AWS default VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the selected subnet in the default VPC"
  value       = data.aws_subnet.selected.id
}