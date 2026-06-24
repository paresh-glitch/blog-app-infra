resource "aws_security_group" "lb_sg" {
  name        = "${var.env}-alb-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id


  # inbound rules
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allows all inbound traffic"
  }
  #outbound rules
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allows all outbound traffic"
  } 

  tags = {
    Name = "${var.env}-alb-sg"
  }
}


resource "aws_lb" "alb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false

  tags = {
    Name = "${var.env}-alb"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.env}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.env}-tg"
    Environment = var.env
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

