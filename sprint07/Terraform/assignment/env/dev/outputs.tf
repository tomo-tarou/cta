output "web_addr" {
  value = "http://${module.application.reservation_web_server_public_ip}"
}

output "api_addr" {
  value = "http://${module.application.reservation_api_server_public_ip}"
}