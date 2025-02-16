provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP traffic on port 80"

  ingress {
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
}

resource "aws_instance" "web" {
  ami                    = "ami-0cb91c7de36eed2cb" # Ubuntu server 24.04 AMI
  instance_type          = "t3.small"
  #key_name               = "exercise-key"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("script.sh")

  tags = {
    Name = "FlaskWebServer"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = ["vpc-00acc805e3b63b146"]
  }
}


resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-0493780a7d4cd5613", "subnet-0563d2e43fe59896f"] # Example subnets
}

resource "aws_lb_target_group" "tg" {
  name     = "flask-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = "vpc-00acc805e3b63b146"

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
