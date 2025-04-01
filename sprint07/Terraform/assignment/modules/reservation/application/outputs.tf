output "reservation_web_server_public_ip" {
  value       = aws_instance.reservation_web_server.public_ip
  description = "The public IP address of the web serve"
}