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
    sed -i "s|baseURL: '.*'|baseURL: 'http://${aws_instance.reservation_api_server.public_ip}'|" /usr/share/nginx/html/cloudtech-reservation-web/config.js
  EOF

  # # # APIサーバーが先に作成されるようにする依存関係を設定
  # depends_on = [aws_instance.reservation_api_server]

  tags = {
    Name = "${var.env}-web-server-01"
  }
}

resource "aws_instance" "reservation_api_server" {
  ami             = "ami-05506fa68391b4cb1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [var.api_sg_id]
  subnet_id       = var.api_subnet_id

  user_data = <<-EOF
    #!/bin/bash
    # 1. yumのアップデート
    yum update -y

    # 2. Gitのインストール
    yum install -y git

    # 3. Goのインストール
    yum install -y golang

    # 4. ソースコードのダウンロード
    cd /home/ec2-user/
    git clone https://github.com/CloudTechOrg/cloudtech-reservation-api.git
    chown -R ec2-user:ec2-user /home/ec2-user/cloudtech-reservation-api

    # 5. サービスの自動起動設定
    cat > /etc/systemd/system/goserver.service << 'EOL'
    [Unit]
    Description=Go Server

    [Service]
    WorkingDirectory=/home/ec2-user/cloudtech-reservation-api
    ExecStart=/usr/bin/go run main.go
    User=ec2-user
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOL

    systemctl daemon-reload
    systemctl enable goserver.service
    systemctl start goserver.service

    # 6. リバースプロキシの設定
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # Nginxの設定ファイルを編集
    cat > /etc/nginx/nginx.conf << 'EOL'
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log;
    pid /run/nginx.pid;

    include /usr/share/nginx/modules/*.conf;

    events {
        worker_connections 1024;
    }

    http {
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        tcp_nodelay         on;
        keepalive_timeout   65;
        types_hash_max_size 4096;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;

        include /etc/nginx/conf.d/*.conf;

        server {
            listen 80;
            server_name _;
            location / {
                proxy_pass http://localhost:8080;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;
                proxy_cache_bypass $http_upgrade;
            }
        }
    }
    EOL

    systemctl restart nginx

    # 7. mysqlのインストール
    yum update -y
    yum install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm -y
    yum install mysql-community-server -y
    systemctl start mysqld
    systemctl enable mysqld

    # 8. RDSに接続および 9. データベースとテーブルの作成
    cat > /tmp/init_db.sql << 'EOL'
    CREATE DATABASE IF NOT EXISTS reservation_db;
    USE reservation_db;
    CREATE TABLE reservation_db.Reservations (
        ID INT AUTO_INCREMENT PRIMARY KEY,
        company_name VARCHAR(255) NOT NULL,
        reservation_date DATE NOT NULL,
        number_of_people INT NOT NULL
    );
    INSERT INTO reservation_db.Reservations (company_name, reservation_date, number_of_people)
    VALUES ('株式会社テスト', '2024-04-21', 5);
    SELECT * FROM reservation_db.Reservations;
    EOL

    # RDSに接続してSQLを実行
    export MYSQL_PWD='your_password_here2025'
    mysql -h ${aws_db_instance.reservation_db.address} -P 3306 -u admin < /tmp/init_db.sql 2>/tmp/mysql_error.log

    # エラーが発生した場合のログ確認
    if [ $? -ne 0 ]; then
        echo "MySQL error occurred. Check /tmp/mysql_error.log"
        cat /tmp/mysql_error.log
    fi
    unset MYSQL_PWD

    # 10. 設定ファイルの作成と権限設定
    cat > /home/ec2-user/cloudtech-reservation-api/.env << EOL
    DB_USERNAME=admin
    DB_PASSWORD=your_password_here2025
    DB_SERVERNAME=${aws_db_instance.reservation_db.address}
    DB_PORT=3306
    DB_NAME=reservation_db
    EOL

    # 所有権を変更
    chown ec2-user:ec2-user /home/ec2-user/cloudtech-reservation-api/.env

    # 11. サービスの再起動
    systemctl restart goserver
  EOF

  tags = {
    Name = "${var.env}-api-server-01"
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
  password = "your_password_here2025"
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
