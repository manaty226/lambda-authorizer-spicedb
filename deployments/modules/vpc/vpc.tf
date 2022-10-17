resource "aws_vpc" "spice_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true 
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.spice_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  tags = {
    "name" =  "spicedb-private-subnet"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id                  = aws_vpc.spice_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  tags = {
    "name" =  "spicedb-private-subnet"
  }
}


resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.spice_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1a"
  tags = {
    "name" =  "spicedb-public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.spice_vpc.id
  tags = {
    Name = "spicedb_igw"
  }
}

resource "aws_eip" "nat_eip" {
  
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.spice_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public_subnet_route_table"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.spice_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    Name = "private_subnet_route_table"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "ecs" {
  name        = "spicedb-alb"
  vpc_id      = "${aws_vpc.spice_vpc.id}"

  # セキュリティグループ内のリソースからNAT Gateway経由でインターネットへのアクセスを許可する
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "spicedb-alb"
  }
}

resource "aws_security_group_rule" "ecs" {
  type = "ingress"
  protocol = "tcp"
  to_port = 50051
  from_port = 0
  source_security_group_id = aws_security_group.ecs.id
  security_group_id = aws_security_group.ecs.id
}

# resource "aws_service_discovery_private_dns_namespace" "spicedb_internal" {
#   name        = "spicedb.internal"
#   description = "spicedb"
#   vpc         = aws_vpc.spice_vpc.id
# }

# resource "aws_service_discovery_service" "spicedb" {
#   name = "spicedb"

#   dns_config {
#     namespace_id = "${aws_service_discovery_private_dns_namespace.spicedb_internal.id}"

#     dns_records {
#       ttl  = 10
#       type = "A"
#     }

#     routing_policy = "MULTIVALUE"
#   }

#   health_check_custom_config {
#     failure_threshold = 1
#   }
# }

output "vpc_id" { value = aws_vpc.spice_vpc.id }
# output "alb_arn" { value = aws_lb.internal_alb.arn }
output "security_group_id" { value = aws_security_group.ecs.id }
output "private_subnet_ids" { value = [aws_subnet.private_1a.id, aws_subnet.private_1c.id] }
# output "service_discovery_arn" { value = aws_service_discovery_service.spicedb.arn }