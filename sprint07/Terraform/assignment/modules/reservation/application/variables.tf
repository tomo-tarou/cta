variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "myip" {
  description = "Administrator's IP address"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "web_subnet_id" {
  description = "ID of the subnet for web servers"
  type        = string
}

variable "api_subnet_01_id" {
  description = "ID of the subnet for API server 01"
  type        = string
}

variable "api_subnet_02_id" {
  description = "ID of the subnet for API server 02"
  type        = string
}

variable "elb_subnet_01_id" {
  description = "ID of the subnet for ELB 01"
  type        = string
}

variable "elb_subnet_02_id" {
  description = "ID of the subnet for ELB 02"
  type        = string
}

variable "web_sg_id" {
  description = "ID of the security group for web servers"
  type        = string
}

variable "api_sg_id" {
  description = "ID of the security group for API servers"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the subnet group for database"
  type        = string
}

variable "db_sg_id" {
  description = "ID of the security group for database"
  type        = string
}

variable "alb_sg_id" {
  description = "ID of the security group for Application Load Balancer"
  type        = string
}

variable "db_password" {
  description = "password for database"
  type        = string
}