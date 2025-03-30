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

  env  = var.env
  myip = var.myip
  vpc_id = var.vpc_id
  web_subnet_id = var.web_subnet_id
  api_subnet_id = var.api_subnet_id
  web_sg_id = var.web_sg_id
  api_sg_id = var.api_sg_id
  db_subnet_group_name = var.db_subnet_group_name
  db_sg_id = var.db_sg_id
}
