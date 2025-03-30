provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "reservation_vpc" {
  cidr_block = "10.0.0.0/20"
  tags = {
    Name = "${var.env}-reservation-vpc"
  }
}

resource "aws_subnet" "reservation_web_subnet_01" {
  vpc_id                  = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = true

  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "${var.env}-web-subnet-01"
  }
}

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

resource "aws_route_table_association" "reservation_web_public_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_web_subnet_01.id
  route_table_id = aws_route_table.reservation_web_public_rtb.id
}

resource "aws_subnet" "reservation_api_subnet_01" {
  vpc_id                  = aws_vpc.reservation_vpc.id
  map_public_ip_on_launch = true

  cidr_block = "10.0.1.0/25"
  tags = {
    Name = "${var.env}-api-subnet-01"
  }
}

resource "aws_route_table" "reservation_api_public_rtb" {
  vpc_id = aws_vpc.reservation_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.reservation_igw.id
  }

  tags = {
    Name = "${var.env}-api-routetable"
  }
}

resource "aws_route_table_association" "reservation_api_public_rtb_assoc" {
  subnet_id      = aws_subnet.reservation_api_subnet_01.id
  route_table_id = aws_route_table.reservation_api_public_rtb.id
}
resource "aws_internet_gateway" "reservation_igw" {
  vpc_id = aws_vpc.reservation_vpc.id

  tags = {
    Name = "${var.env}-reservation-ig"
  }
}

resource "aws_security_group" "reservation_web_sg" {
  vpc_id      = aws_vpc.reservation_vpc.id
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

resource "aws_instance" "reservation_web_server" {
  ami             = "ami-05506fa68391b4cb1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [aws_security_group.reservation_web_sg.id]
  subnet_id       = aws_subnet.reservation_web_subnet_01.id

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

  # APIサーバーが先に作成されるようにする依存関係を設定
  depends_on = [aws_instance.reservation_api_server]

  tags = {
    Name = "${var.env}-web-server-01"
  }
}

resource "aws_security_group" "reservation_api_sg" {
  vpc_id      = aws_vpc.reservation_vpc.id
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

resource "aws_instance" "reservation_api_server" {
  ami             = "ami-05506fa68391b4cb1"
  instance_type   = "t2.micro"
  key_name        = "test-ec2-key"
  security_groups = [aws_security_group.reservation_api_sg.id]
  subnet_id       = aws_subnet.reservation_api_subnet_01.id

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
  EOF

  tags = {
    Name = "${var.env}-api-server-01"
  }
}
