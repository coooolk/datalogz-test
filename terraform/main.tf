#creating security groups
#sg for load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP traffic to load balancer on port 80"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

#sg for ec2 instance
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP ingress traffic on port 5000"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5000
    to_port     = 5000
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





#creating ec2 instance
resource "aws_instance" "web" {
  ami                    = var.ami_id # Ubuntu server 24.04 AMI on ap-south-1
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = module.vpc.private_subnets[0]

  associate_public_ip_address = false

  user_data                   = file("/home/pico/datalogz/script.sh") #using script.sh as user data to install and run app.py on created ec2 instance
  user_data_replace_on_change = true

  depends_on = [module.vpc.enable_nat_gateway]

  tags = {
    Name = "FlaskWebServer"
  }
}




#creating alb, target group, listener and attaching created ec2 instance to target group.
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "tg" {
  name     = "flask-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

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





#displaying relevant info to console
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

#output "instance_public_ip" {
#  description = "Public IP address of the EC2 instance"
#  value       = aws_instance.web.public_ip
#}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "lb_dns_name" {
  description = "DNS name of Load Balancer"
  value       = aws_lb.app_lb.dns_name
}