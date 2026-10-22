variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitted to access SSH; empty disables SSH ingress"
  type        = string
  default     = ""
}

variable "monitoring_cidr" {
  description = "CIDR permitted to access Prometheus and Grafana; empty disables public ingress to both"
  type        = string
  default     = ""
}