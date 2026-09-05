# versions.tf — pins the Terraform version and the AWS provider version
# this configuration was written and tested against. Without this, the
# same main.tf could behave differently on two different laptops simply
# because they have different provider versions installed — the exact
# kind of silent inconsistency this whole class is about avoiding.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}