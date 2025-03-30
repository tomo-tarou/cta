# module "reservation" {
#   source = "../../modules/reservation"

#   env  = var.env
#   myip = var.myip
# }

module "network" {
  source = "../../modules/reservation/network"

  env  = var.env
  myip = var.myip
}

module "security" {
  source = "../../modules/reservation/security"
  vpc_id = module.network.vpc_id

  env  = var.env
  myip = var.myip
}

module "application" {
  source = "../../modules/reservation/application"

  env  = var.env
  myip = var.myip
  vpc_id = module.network.vpc_id
  web_subnet_id = module.network.web_subnet_id
  api_subnet_id = module.network.api_subnet_id
  web_sg_id = module.security.web_sg_id
  api_sg_id = module.security.api_sg_id
  db_subnet_group_name = module.network.db_subnet_group_name
  db_sg_id            = module.security.db_sg_id
}
