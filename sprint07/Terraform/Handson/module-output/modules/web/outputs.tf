output "web_ec2_public_ip" {
  value = aws_instance.web_ec2.public_ip
  description = "The public IP address of the web server"
}