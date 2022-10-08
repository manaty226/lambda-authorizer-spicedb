variable alb_arn {}
variable security_group {}
variable subnet {}

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
  container_definitions    = data.template_file.spicedb_task.template
}

resource "aws_ecs_service" "spicedb" {
  name                              = "spicedb_service"
  cluster                           = aws_ecs_cluster.spicedb_cluster.arn
  task_definition                   = aws_ecs_task_definition.spicedb.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [var.security_group]

    subnets = [
      var.subnet,
    ]
  }

  load_balancer {
    target_group_arn = var.alb_arn
    container_name   = "spicedb"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# module "nginx_sg" {
#   source      = "./security_group"
#   name        = "nginx-sg"
#   vpc_id      = module.vpc.aws_vpc.spice_vpc.id
#   port        = 80
#   cidr_blocks = [module.vpc.aws_vpc.spice_vpc.cidr_block]
# }