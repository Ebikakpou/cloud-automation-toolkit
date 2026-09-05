# variables.tf — every value in main.tf that's likely to change lives
# here, with a description and a sensible default, exactly like
# values.yaml did for the Helm chart last class. Nobody should ever
# need to hunt through main.tf to find a hardcoded value — if it can
# change, it's a variable.

variable "aws_region" {
  description = "AWS region to provision CloudShift Store into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type — t2.micro is free-tier eligible, plenty for this class"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an EC2 key pair already created in your AWS account, for SSH access"
  type        = string

  # No default on purpose — this is specific to your AWS account, and a
  # wrong default here would be worse than forcing you to set it.
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
  description = "CIDR block allowed to SSH into the instance. Restrict this to your own IP in anything beyond a class lab."
  type        = string
  default     = "0.0.0.0/0"
}