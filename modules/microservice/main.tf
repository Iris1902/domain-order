resource "aws_security_group" "sg" {
  name_prefix = "${var.name}-sg"
  vpc_id      = var.vpc_id

  # SSH (solo tú deberías limitar por IP si es producción)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 80 (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puertos de microservicios (4000-4003)
  ingress {
    from_port   = 4000
    to_port     = 4003
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

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data = base64encode(templatefile("${path.module}/docker-compose.tpl", {
    image_order_create = "ievinan/microservice-order-create:${var.branch}",
    port_order_create  = 4000,
    image_order_read   = "ievinan/microservice-order-read:${var.branch}",
    port_order_read    = 4001,
    image_order_add    = "ievinan/microservice-order-add:${var.branch}",
    port_order_add     = 4002,
    image_order_delete = "ievinan/microservice-order-delete:${var.branch}",
    port_order_delete  = 4003,
    mongo_url          = var.mongo_url
  }))
}

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [var.subnet1, var.subnet2]
}

resource "aws_lb_target_group" "tg_create" {
  name     = "${var.name}-tg-create"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/order-create/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "tg_read" {
  name     = "${var.name}-tg-read"
  port     = 4001
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/order-read/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "tg_add" {
  name     = "${var.name}-tg-add"
  port     = 4002
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/order-add/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "tg_delete" {
  name     = "${var.name}-tg-delete"
  port     = 4003
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/order-delete/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_create.arn
  }
}

resource "aws_lb_listener_rule" "rule_create" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["/order-create*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_create.arn
  }
}

resource "aws_lb_listener_rule" "rule_read" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 101
  condition {
    path_pattern {
      values = ["/order-read*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_read.arn
  }
}

resource "aws_lb_listener_rule" "rule_add" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 102
  condition {
    path_pattern {
      values = ["/order-add*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_add.arn
  }
}

resource "aws_lb_listener_rule" "rule_delete" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 103
  condition {
    path_pattern {
      values = ["/order-delete*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_delete.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [var.subnet1, var.subnet2]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns    = [
    aws_lb_target_group.tg_create.arn,
    aws_lb_target_group.tg_read.arn,
    aws_lb_target_group.tg_add.arn,
    aws_lb_target_group.tg_delete.arn
  ]
  lifecycle {
    create_before_destroy = true
  }
}
