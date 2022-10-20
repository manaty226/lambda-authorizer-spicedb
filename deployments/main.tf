provider "aws" {
  region = "ap-northeast-1"
}


module "acm" {
  source = "./modules/acm"
}

module "vpc" {
  source = "./modules/vpc"
}

module "lambda" {
  source = "./modules/lambda"
  subnet_id = module.vpc.private_subnet_ids[0]
  security_group_id = module.vpc.security_group_id
  alb_host = module.spicedb.lb_dns
  acm_certificate_arn = module.acm.acm_certificate_arn
}

module "api" {
  source = "./modules/api"
  authorizer_invoke_arn = module.lambda.authorizer_invoke_arn
}

module "spicedb" {
  source = "./modules/ecs"
  
  acm_certificate_arn = module.acm.acm_certificate_arn
  subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.vpc.security_group_id
  vpc_id = module.vpc.vpc_id
}