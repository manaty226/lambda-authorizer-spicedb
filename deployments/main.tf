provider "aws" {
  region = "ap-northeast-1"
}

module "api" {
  source = "./modules/api"
}

module "vpc" {
  source = "./modules/vpc"
}

module "spicedb" {
  source = "./modules/ecs"

  alb_arn = module.vpc.alb_arn
  subnet = module.vpc.private_subnet
  security_group = module.vpc.security_group
}