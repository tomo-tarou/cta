#----------------------------------------
# セキュリティグループの作成
#----------------------------------------
resource "aws_security_group" "reservation_web_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.env}-web-sg"
  description = "Security group for web servers in the ${var.env} environment"

  ingress {
    description = "Allow HTTP traffic from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}/32"]
  }

  ingress {
    description = "Allow SSH access from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-web-sg"
  }
}

resource "aws_security_group" "reservation_api_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.env}-api-sg"
  description = "Security group for api servers in the ${var.env} environment"

  ingress {
    description = "Allow HTTP traffic from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}/32"]
  }

  ingress {
    description = "Allow SSH access from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-api-sg"
  }
}

resource "aws_security_group" "reservation_db_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.env}-db-sg"
  description = "Security group for RDS in the ${var.env} environment"

  ingress {
    description     = "Allow MySQL access from API server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.reservation_api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-db-sg"
  }
}

#----------------------------------------
# IAMユーザーグループの作成
#----------------------------------------
resource "aws_iam_group" "server_management" {
  name = "${var.env}-server-management-group"
}

resource "aws_iam_group" "database_management" {
  name = "${var.env}-database-management-group"
}

resource "aws_iam_group" "user_management" {
  name = "${var.env}-user-management-group"
}

#----------------------------------------
# IAMユーザーグループへのポリシーアタッチ
#----------------------------------------
resource "aws_iam_group_policy_attachment" "server_management_policy" {
  group      = aws_iam_group.server_management.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_group_policy_attachment" "database_management_policy" {
  group      = aws_iam_group.database_management.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_group_policy_attachment" "user_management_policy" {
  group      = aws_iam_group.user_management.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

#----------------------------------------
# IAMユーザーの作成
#----------------------------------------
resource "aws_iam_user" "taro" {
  name = "${var.env}-test-taro"
}

resource "aws_iam_user" "jiro" {
  name = "${var.env}-test-jiro"
}

resource "aws_iam_user" "saburo" {
  name = "${var.env}-test-saburo"
}

resource "aws_iam_user" "shiro" {
  name = "${var.env}-test-shiro"
}

#----------------------------------------
# ユーザーをグループに所属させる
#----------------------------------------
resource "aws_iam_user_group_membership" "taro_membership" {
  user   = aws_iam_user.taro.name
  groups = [aws_iam_group.user_management.name]
}

resource "aws_iam_user_group_membership" "jiro_membership" {
  user   = aws_iam_user.jiro.name
  groups = [aws_iam_group.server_management.name]
}

resource "aws_iam_user_group_membership" "saburo_membership" {
  user   = aws_iam_user.saburo.name
  groups = [aws_iam_group.database_management.name]
}

resource "aws_iam_user_group_membership" "shiro_membership" {
  user   = aws_iam_user.shiro.name
  groups = [
    aws_iam_group.server_management.name,
    aws_iam_group.database_management.name
  ]
}