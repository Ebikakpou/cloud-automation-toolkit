variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudshift-store"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP with /32, or empty to disable SSH ingress"
  type        = string
  default     = ""
}

variable "monitoring_cidr" {
  description = "Trusted CIDR for Prometheus and Grafana, or empty to disable their ingress"
  type        = string
  default     = ""
}