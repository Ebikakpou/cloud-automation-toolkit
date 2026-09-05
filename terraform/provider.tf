# provider.tf — tells Terraform which cloud, and which region in it, to
# talk to. Every resource below is created through this one provider
# block. Swapping clouds later (or adding a second one) means adding a
# provider block here, not rewriting every resource.
provider "aws" {
  region = var.aws_region
}