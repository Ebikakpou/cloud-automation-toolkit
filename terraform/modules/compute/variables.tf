variable "subnet_id" {
  description = "Subnet where the EC2 instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}