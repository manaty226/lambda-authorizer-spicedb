
resource "aws_vpc" "spice_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true 
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.spice_vpc
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  tags = {
    "name" =  "spicedb-private-subnet"
  }
}

resource "aws_security_group" "alb" {
  name        = "spicedb-alb"
  vpc_id      = "${aws_vpc.spice_vpc.id}"

  # セキュリティグループ内のリソースからインターネットへのアクセスを許可する
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "spicedb-alb"
  }
}

resource "aws_lb" "internal_alb" {
  name               = "spice-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.private_1a : subnet.id]

  enable_deletion_protection = false
}

output "alb_arn" { value = aws_lb.internal_alb.arn }
output "security_group" { value = aws_security_group.alb }
output "private_subnet" { value = aws_subnet.private_1a }