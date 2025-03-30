output "reservation_web_server_public_ip" {
  value       = aws_instance.reservation_web_server.public_ip
  description = "The public IP address of the web serve"
}

output "reservation_api_server_public_ip" {
  value       = aws_instance.reservation_api_server.public_ip
  description = "The public IP address of the api serve"
}