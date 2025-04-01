output "web_addr" {
  value = "http://${module.application.reservation_web_server_public_ip}"
}