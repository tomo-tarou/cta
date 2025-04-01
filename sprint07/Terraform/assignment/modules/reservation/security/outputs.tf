output "web_sg_id" {
  description = "ID of the security group for web servers"
  value       = aws_security_group.reservation_web_sg.id
}

output "api_sg_id" {
  description = "ID of the security group for API servers"
  value       = aws_security_group.reservation_api_sg.id
}

output "db_sg_id" {
  description = "ID of the security group for database"
  value       = aws_security_group.reservation_db_sg.id
}

output "alb_sg_id" {
  description = "ID of the security group for Application Load Balancer"
  value       = aws_security_group.reservation_alb_sg.id
}