#----------------------------------------
# EC2インスタンスの作成
#----------------------------------------
resource "aws_instance" "reservation_web_server" {
  ami             = "ami-05506fa68391b4cb1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [var.web_sg_id]
  subnet_id       = var.web_subnet_id

  user_data = <<-EOF
    #!/bin/bash

    # 1. システムの更新
    yum update -y

    # 2. Gitのインストール
    yum install -y git

    # 3. nginxのインストール
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # 5. ソースコードの配置
    cd /usr/share/nginx/html/
    git clone https://github.com/CloudTechOrg/cloudtech-reservation-web.git

    # 6. Nginxのデフォルト設定の変更
    sed -i 's|root[[:space:]]\+/usr/share/nginx/html;|root /usr/share/nginx/html/cloudtech-reservation-web;|' /etc/nginx/nginx.conf
    systemctl restart nginx

    # 7. API接続先の設定
    sed -i "s|baseURL: '.*'|baseURL: 'http://${aws_lb.reservation_alb.dns_name}'|" /usr/share/nginx/html/cloudtech-reservation-web/config.js
  EOF

  # ALBが先に作成されるように依存関係を設定
  depends_on = [aws_lb.reservation_alb]

  tags = {
    Name = "${var.env}-web-server-01"
  }
}

resource "aws_instance" "reservation_api_server_01" {
  ami             = "ami-070d2d7c127d1a7a1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [var.api_sg_id]
  subnet_id       = var.api_subnet_01_id
  depends_on      = [aws_db_instance.reservation_db]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # ログファイルの設定
    LOGFILE="/var/log/user_data_script.log"
    exec > >(tee -a $LOGFILE) 2>&1

    echo "Starting table and data initialization at $(date)"

    # RDS接続情報
    RDS_HOST="${aws_db_instance.reservation_db.address}"
    RDS_USER="admin"
    RDS_PASS="${var.db_password}"
    DB_NAME="reservation_db"

    # テーブル作成SQL
    echo "Creating table if not exists..."
    mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS $DB_NAME -e "
      CREATE TABLE IF NOT EXISTS Reservations (
        ID INT AUTO_INCREMENT PRIMARY KEY,
        company_name VARCHAR(255) NOT NULL,
        reservation_date DATE NOT NULL,
        number_of_people INT NOT NULL
      );
    "

    # レコード数をチェック
    echo "Checking if data exists..."
    RECORD_COUNT=$(mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS $DB_NAME -sN -e "
      SELECT COUNT(*) FROM Reservations;
    ")

    # レコードが0件の場合のみデータを挿入
    if [ "$RECORD_COUNT" -eq "0" ]; then
      echo "No records found. Inserting initial data..."
      mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS $DB_NAME -e "
        INSERT INTO Reservations (company_name, reservation_date, number_of_people)
        VALUES ('株式会社テスト', '2024-04-21', 5);
      "
      echo "Initial data inserted successfully."
    else
      echo "Data already exists. Skipping data insertion."
    fi

    # サービス再起動
    echo "Restarting application service..."
    systemctl restart goserver

    echo "Table and data initialization completed at $(date)"
  EOF

  tags = {
    Name = "${var.env}-api-server-01"
  }
}

resource "aws_instance" "reservation_api_server_02" {
  ami             = "ami-070d2d7c127d1a7a1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [var.api_sg_id]
  subnet_id       = var.api_subnet_02_id

  # RDSインスタンスが先に作成されるように依存関係を設定
  depends_on = [aws_db_instance.reservation_db]

  tags = {
    Name = "${var.env}-api-server-02"
  }
}

#----------------------------------------
# RDSインスタンスの作成
#----------------------------------------
resource "aws_db_instance" "reservation_db" {
  identifier = "${var.env}-reservation-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "reservation_db"
  username = "admin"
  password = "${var.db_password}"
  port     = 3306

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.db_sg_id]
  availability_zone      = "ap-northeast-1a"
  multi_az              = false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  skip_final_snapshot  = true
  publicly_accessible = false

  tags = {
    Name = "${var.env}-reservation-db"
  }
}

#----------------------------------------
# アプリケーションロードバランサーの作成
#----------------------------------------
resource "aws_lb" "reservation_alb" {
  name               = "${var.env}-reservation-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.elb_subnet_01_id, var.elb_subnet_02_id]

  tags = {
    Name = "${var.env}-reservation-alb"
  }
}

#----------------------------------------
# ターゲットグループの作成
#----------------------------------------
resource "aws_lb_target_group" "reservation_api_tg" {
  name     = "${var.env}-reservation-api-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.env}-reservation-api-tg"
  }
}

#----------------------------------------
# リスナーの作成
#----------------------------------------
resource "aws_lb_listener" "reservation_alb_listener" {
  load_balancer_arn = aws_lb.reservation_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reservation_api_tg.arn
  }
}

#----------------------------------------
# ターゲットグループへのターゲット追加
#----------------------------------------
resource "aws_lb_target_group_attachment" "api_server_01" {
  target_group_arn = aws_lb_target_group.reservation_api_tg.arn
  target_id        = aws_instance.reservation_api_server_01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "api_server_02" {
  target_group_arn = aws_lb_target_group.reservation_api_tg.arn
  target_id        = aws_instance.reservation_api_server_02.id
  port             = 80
}

#----------------------------------------
# 起動テンプレートの作成
#----------------------------------------
resource "aws_launch_template" "api_server_lt" {
  name   = "${var.env}-api-server-lt"
  image_id      = "ami-070d2d7c127d1a7a1"
  instance_type = "t2.micro"
  key_name      = "test-ec2-key"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.api_sg_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-api-server"
    }
  }
}

#----------------------------------------
# Auto Scalingグループの作成
#----------------------------------------
resource "aws_autoscaling_group" "reservation_api_asg" {
  name               = "${var.env}-api-asg"
  desired_capacity    = 2
  max_size           = 4
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.reservation_api_tg.arn]
  vpc_zone_identifier = [var.api_subnet_01_id, var.api_subnet_02_id]
  # RDSインスタンスが先に作成されるように依存関係を設定
  depends_on = [aws_db_instance.reservation_db]

  launch_template {
    id      = aws_launch_template.api_server_lt.id  # 新しく作成したLaunch Templateを使用
    version = "$Latest"
  }
}

#----------------------------------------
# ターゲット追跡ポリシーの作成
#----------------------------------------
resource "aws_autoscaling_policy" "api_server_cpu_policy" {
  name               = "${var.env}-api-server-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.reservation_api_asg.name
  policy_type        = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}
