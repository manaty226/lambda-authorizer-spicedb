provider "aws" {
  region = "ap-northeast-1"
}

module "api" {
  source = "./modules/api"
}

# resource "aws_vpc" "spice_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true 
# }

# resource "aws_subnet" "private_1a" {
#   vpc_id                  = aws_vpc.spice_vpc
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "ap-northeast-1a"
#   tags = "spicedb-private-subnet"
# }

# resource "aws_lb" "internal_alb" {
#   name               = "spice-internal-alb"
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = [for subnet in aws_subnet.private : subnet.id]

#   enable_deletion_protection = false
# }

# resource "aws_ecs_cluster" "spicedb_cluster" {
#   name = "spicedb-cluster"
# }

# resource "aws_ecs_task_definition" "spicedb" {
#   family                   = "spicedb"
#   cpu                      = "256"
#   memory                   = "512"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   container_definitions    = file("./container_definitions.json")
# }

# resource "aws_ecs_service" "spicedb" {
#   name                              = "spicedb_service"
#   cluster                           = aws_ecs_cluster.spicedb_cluster.arn
#   task_definition                   = aws_ecs_task_definition.spicedb.arn
#   desired_count                     = 1
#   launch_type                       = "FARGATE"
#   platform_version                  = "1.3.0"
#   health_check_grace_period_seconds = 60

#   network_configuration {
#     assign_public_ip = false
#     security_groups  = [module.nginx_sg.security_group_id]

#     subnets = [
#       aws_subnet.private_1a.id,
#     ]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.example.arn
#     container_name   = "example"
#     container_port   = 80
#   }

#   lifecycle {
#     ignore_changes = [task_definition]
#   }
# }

# module "nginx_sg" {
#   source      = "./security_group"
#   name        = "nginx-sg"
#   vpc_id      = aws_vpc.example.id
#   port        = 80
#   cidr_blocks = [aws_vpc.example.cidr_block]
# }