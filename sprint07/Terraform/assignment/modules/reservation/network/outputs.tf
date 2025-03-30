output "vpc_id" {
  value = aws_vpc.reservation_vpc.id
}

output "web_subnet_id" {
  value = aws_subnet.reservation_web_subnet_01.id
}

output "api_subnet_id" {
  value = aws_subnet.reservation_api_subnet_01.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.reservation_db_subnet_group.name
}

output "db_subnet_01_id" {
  value = aws_subnet.reservation_db_subnet_01.id
}

output "db_subnet_02_id" {
  value = aws_subnet.reservation_db_subnet_02.id
}