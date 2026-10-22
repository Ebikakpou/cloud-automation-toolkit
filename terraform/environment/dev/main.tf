module "network" {
  source = "../../modules/network"
}

module "security" {
  source = "../../modules/security"

  vpc_id           = module.network.vpc_id
  project_name     = var.project_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr
  monitoring_cidr  = var.monitoring_cidr
}

module "compute" {
  source = "../../modules/compute"

  subnet_id         = module.network.subnet_id
  security_group_id = module.security.security_group_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  environment       = var.environment
  project_name      = var.project_name
}