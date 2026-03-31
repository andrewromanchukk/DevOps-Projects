
## Get current VPC id

data "aws_vpc" "current_vpc" {
  filter {
    name = "tag:Name"
    values = [ "MyVPC" ]
}
}

data "aws_subnet" "pub_sub_a" {
  filter {
    name = "tag:Name"
    values = [ "Public_A" ]
}
}

data "aws_subnet" "pub_sub_b" {
  filter {
    name = "tag:Name"
    values = [ "Public_B" ]
}
}

## Create ALB security group
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = data.aws_vpc.current_vpc.id


  dynamic "ingress" {
    for_each = [ 80, 443 ]
    content {
        from_port   = ingress.value
        to_port     = ingress.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Create ALB

resource "aws_lb" "app" {
  name               = "my-alb"
  load_balancer_type = "application"
  subnets            = [
    data.aws_subnet.pub_sub_a.id,
    data.aws_subnet.pub_sub_b.id
  ]
  security_groups = [aws_security_group.alb_sg.id]

  tags = merge(var.common_tags, {
    Name = "my-alb"
  })
}

## Target group

resource "aws_lb_target_group" "app" {
  name        = "app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip" # or "ip" for ECS

  vpc_id = data.aws_vpc.current_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }
}

## Listener 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
## Output LB DNS name 
output "alb_dns" {
  value = aws_lb.app.dns_name
}