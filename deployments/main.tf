provider "aws" {
  region = "ap-northeast-1"
}


module "acm" {
  source = "./modules/acm"
  # server_private_key_pem = module.certificate.server_private_key
  # server_crt_pem = module.certificate.server_crt_pem
  # root_crt_pem = module.certificate.root_crt_pem
}

module "vpc" {
  source = "./modules/vpc"
}

module "api" {
  source = "./modules/api"
  subnet_id = module.vpc.private_subnet_ids[0]
  security_group_id = module.vpc.security_group_id
  alb_host = module.spicedb.lb_dns
  acm_certificate_arn = module.acm.acm_certificate_arn
}

module "spicedb" {
  source = "./modules/ecs"
  
  acm_certificate_arn = module.acm.acm_certificate_arn
  # alb_arn = module.vpc.alb_arn
  subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.vpc.security_group_id
  vpc_id = module.vpc.vpc_id
  # service_discovery_arn = module.vpc.service_discovery_arn
}