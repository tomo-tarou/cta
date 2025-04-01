provider "aws" {
  region = "ap-northeast-1"
}

#----------------------------------------
# VPCの作成
#----------------------------------------
resource "aws_vpc" "reservation_vpc" {
  cidr_block = "10.0.0.0/20"
  tags = {
    Name = "${var.env}-reservation-vpc"
  }
}

#----------------------------------------
# サブネットの作成
#----------------------------------------
resource "aws_subnet" "reservation_web_subnet_01" {
  vpc_id                  = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = true

  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "${var.env}-web-subnet-01"
  }
}

resource "aws_subnet" "reservation_api_subnet_01" {
  vpc_id            = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = false
  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.1.0/25"
  tags = {
    Name = "${var.env}-api-subnet-01"
  }
}

resource "aws_subnet" "reservation_api_subnet_02" {
  vpc_id            = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = false
  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.4.0/25"
  tags = {
    Name = "${var.env}-api-subnet-02"
  }
}

resource "aws_subnet" "reservation_elb_subnet_01" {
  vpc_id                  = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  cidr_block = "10.0.5.0/25"
  tags = {
    Name = "${var.env}-elb-subnet-01"
  }
}

resource "aws_subnet" "reservation_elb_subnet_02" {
  vpc_id                  = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  cidr_block = "10.0.6.0/25"
  tags = {
    Name = "${var.env}-elb-subnet-02"
  }
}

resource "aws_subnet" "reservation_db_subnet_01" {
  vpc_id     = aws_vpc.reservation_vpc.id
  cidr_block = "10.0.2.0/25"

  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.env}-db-subnet-01"
  }
}

resource "aws_subnet" "reservation_db_subnet_02" {
  vpc_id     = aws_vpc.reservation_vpc.id
  cidr_block = "10.0.3.0/25"

  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.env}-db-subnet-02"
  }
}

#----------------------------------------
# ルートテーブルの作成
#----------------------------------------
resource "aws_route_table" "reservation_web_public_rtb" {
  vpc_id = aws_vpc.reservation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.reservation_igw.id
  }

  tags = {
    Name = "${var.env}-web-routetable"
  }
}

resource "aws_route_table" "reservation_api_private_rtb" {
  vpc_id = aws_vpc.reservation_vpc.id

  tags = {
    Name = "${var.env}-api-routetable"
  }
}

resource "aws_route_table" "reservation_elb_public_rtb" {
  vpc_id = aws_vpc.reservation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.reservation_igw.id
  }

  tags = {
    Name = "${var.env}-elb-routetable"
  }
}

#----------------------------------------
# サブネットにルートテーブルを紐づけ
#----------------------------------------
resource "aws_route_table_association" "reservation_web_public_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_web_subnet_01.id
  route_table_id = aws_route_table.reservation_web_public_rtb.id
}

resource "aws_route_table_association" "reservation_api_subnet_01_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_api_subnet_01.id
  route_table_id = aws_route_table.reservation_api_private_rtb.id
}

resource "aws_route_table_association" "reservation_api_subnet_02_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_api_subnet_02.id
  route_table_id = aws_route_table.reservation_api_private_rtb.id
}

resource "aws_route_table_association" "reservation_elb_subnet_01_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_elb_subnet_01.id
  route_table_id = aws_route_table.reservation_elb_public_rtb.id
}

resource "aws_route_table_association" "reservation_elb_subnet_02_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_elb_subnet_02.id
  route_table_id = aws_route_table.reservation_elb_public_rtb.id
}

#----------------------------------------
# インターネットゲートウェイの作成
#----------------------------------------
resource "aws_internet_gateway" "reservation_igw" {
  vpc_id = aws_vpc.reservation_vpc.id

  tags = {
    Name = "${var.env}-reservation-ig"
  }
}

#----------------------------------------
# サブネットグループの作成
#----------------------------------------
resource "aws_db_subnet_group" "reservation_db_subnet_group" {
  name        = "${var.env}-db-subnet-group"
  description = "DB subnet group for reservation system"
  subnet_ids  = [
    aws_subnet.reservation_db_subnet_01.id,
    aws_subnet.reservation_db_subnet_02.id
  ]

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

