output "web_sg_id" {
  value = aws_security_group.reservation_web_sg.id
}

output "api_sg_id" {
  value = aws_security_group.reservation_api_sg.id
}

output "db_sg_id" {
  value = aws_security_group.reservation_db_sg.id
}