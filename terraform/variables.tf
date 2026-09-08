
variable "aws_region" {
  description = "AWS region to provision cloudshift store into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "AWS instance type to provision cloudshift store into"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an EC2 key pair already created in your AWS account for SSH access"
  type        = string
}

variable "environment" {
  description = "Environment name — shows up in tags and in the app's own status strip"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Used to name and tag every resource this configuration creates"
  type        = string
  default     = "cloudshift-store"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance."
  type        = string
  default     = "0.0.0.0/0"
}
