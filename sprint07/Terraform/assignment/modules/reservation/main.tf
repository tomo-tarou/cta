module "network" {
  source = "./network"

  env  = var.env
  myip = var.myip
}

module "security" {
  source = "./security"

  env  = var.env
  myip = var.myip
  vpc_id = var.vpc_id
}

module "application" {
  source = "./application"

  env                = var.env
  myip               = var.myip
  vpc_id             = module.network.vpc_id
  web_subnet_id      = module.network.web_subnet_id
  api_subnet_01_id   = module.network.api_subnet_01_id
  api_subnet_02_id   = module.network.api_subnet_02_id
  elb_subnet_01_id   = module.network.elb_subnet_01_id
  elb_subnet_02_id   = module.network.elb_subnet_02_id
  web_sg_id          = module.security.web_sg_id
  api_sg_id          = module.security.api_sg_id
  db_subnet_group_name = module.network.db_subnet_group_name
  db_sg_id           = module.security.db_sg_id
  alb_sg_id          = module.security.alb_sg_id
  db_password = var.db_password
}

