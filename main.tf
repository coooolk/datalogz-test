provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP traffic on port 80"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-00bb6a80f01f03502" # Ubuntu server 24.04 AMI
  instance_type          = "t2.micro"
  key_name               = "default-aws-key-pair"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("script.sh")

  tags = {
    Name = "FlaskWebServer"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = ["vpc-027c5aa72f29ede16"]
  }
}


resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-0f73f26d3e8a041a7", "subnet-0d7ae98be33c81945", "subnet-05bf5b97322f4d0a6"] # Example subnets
}

resource "aws_lb_target_group" "tg" {
  name     = "flask-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = "vpc-027c5aa72f29ede16"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "5000"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web.id
  port             = 5000
}


output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}
