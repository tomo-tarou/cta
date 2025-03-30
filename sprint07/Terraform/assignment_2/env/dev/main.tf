module "reservation" {
  source = "../../modules/reservation"

  env  = var.env
  myip = var.myip
}
