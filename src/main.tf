# Provider設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 使用可能なAZを取得
data "aws_availability_zones" "available" {
  state = "available"
}

# 変数定義
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

resource "random_string" "unique" {
  length  = 6
  upper   = false
  lower   = true
  special = false
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-handson"
}


# VPC設定
data "aws_vpc" "vpc01" {
  filter {
    name   = "tag:Name"
    values = ["prod-handson-vpc01"]
  }
}
data "aws_subnet" "subnet-1a" {
  filter {
    name   = "tag:Name"
    values = ["prod-handson-vpc01-sub-pub01a"]
  }
}

data "aws_subnet" "subnet-1c" {
  filter {
    name   = "tag:Name"
    values = ["prod-handson-vpc01-sub-pub01c"]
  }
}

# 出力値
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.vpc01.id
}

output "subnet_id-1a" {
  description = "ID of the Subnet"
  value       = data.aws_subnet.subnet-1a.id
}

output "subnet_id-1c" {
  description = "ID of the Subnet"
  value       = data.aws_subnet.subnet-1c.id
}


# 最新のAmazon Linux 2023 AMIを取得
data "aws_ami" "amazon_linux2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# セキュリティグループ
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${random_string.unique.result}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.vpc01.id


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-ec2-sg"
  }
}

# EC2インスタンス - パブリックサブネット1
resource "aws_instance" "public_1" {
  ami                    = data.aws_ami.amazon_linux2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.subnet-1a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(local.nginx_userdata_1)

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-ec2-public-1"
  }
}

# EC2インスタンス - パブリックサブネット2
resource "aws_instance" "public_2" {
  ami                    = data.aws_ami.amazon_linux2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.subnet-1c.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = base64encode(local.nginx_userdata_2)

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-ec2-public-2"
  }
}


# Nginx起動用userdata script
locals {
  nginx_userdata_1 = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    sed -i 's/x!/x!-01/g' /usr/share/nginx/html/index.html
  EOF

  nginx_userdata_2 = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    sed -i 's/x!/x!-02/g' /usr/share/nginx/html/index.html

  EOF
}

# EC2インスタンスのIPアドレスを出力
output "ec2_public_1_public_ip" {
  description = "Public IP of EC2 instance in public subnet 1"
  value       = aws_instance.public_1.public_ip
}

output "ec2_public_2_public_ip" {
  description = "Public IP of EC2 instance in public subnet 2"
  value       = aws_instance.public_2.public_ip
}

# ALB用セキュリティグループ
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${random_string.unique.result}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.vpc01.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${random_string.unique.result}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.subnet-1a.id, data.aws_subnet.subnet-1c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-alb"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-${random_string.unique.result}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc01.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-${random_string.unique.result}-tg"
  }
}

# ターゲットグループにEC2インスタンスを登録
resource "aws_lb_target_group_attachment" "public_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.public_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "public_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.public_2.id
  port             = 80
}

# ALBリスナー
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALBのDNS名を出力
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}