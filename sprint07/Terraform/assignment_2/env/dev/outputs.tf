output "web_addr" {
  value = "http://${module.reservation.reservation_web_server_public_ip}"
}

output "api_addr" {
  value = "http://${module.reservation.reservation_api_server_public_ip}"
}

