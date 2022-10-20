variable acm_certificate_arn {}
variable security_group_id {}
variable subnet_ids {}
variable vpc_id {}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy" "acm_policy" {
  name = "default"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "exec_policy" {
  name = "default"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
             "ssmmessages:CreateControlChannel",
             "ssmmessages:CreateDataChannel",
             "ssmmessages:OpenControlChannel",
             "ssmmessages:OpenDataChannel"
        ],
       "Resource": "*"
       }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "spicedb" {
  name              = "/ecs/spicedb"
  retention_in_days = 30
}

resource "aws_ecs_cluster" "spicedb_cluster" {
  name = "spicedb-cluster"
}

data "template_file" "spicedb_task" {
  template = "${file("${path.module}/container_definitions.json")}"
  vars = {
  }
}

resource "aws_ecs_task_definition" "spicedb" {
  family                   = "spicedb"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = data.template_file.spicedb_task.rendered
}

resource "aws_ecs_service" "spicedb" {
  name                              = "spicedb_service"
  cluster                           = aws_ecs_cluster.spicedb_cluster.arn
  task_definition                   = aws_ecs_task_definition.spicedb.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = true
    security_groups  = [var.security_group_id]

    subnets = var.subnet_ids
  }
  
  load_balancer {
      target_group_arn = "${aws_lb_target_group.ecs.arn}"
      container_name   = "spicedb"
      container_port   = "50051"
  }
  
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_lb" "internal_lb" {
  name               = "spice-internal-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}



resource "aws_lb_target_group" "ecs" {
  name                 = "spicedb"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  port                 = 50051
  protocol             = "HTTP"
  protocol_version     = "GRPC"
  deregistration_delay = 300
  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 12
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  depends_on = [aws_lb.internal_lb]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.acm_certificate_arn}" 
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "lb_dns" { value = aws_lb.internal_lb.dns_name }