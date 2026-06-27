provider "aws" {
  region = "ap-south-1"
}

data "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"
}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  env             = "${var.env}-vpc"
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "ecr" {
  source = "./modules/ecr"
  env = var.env
  repo_names = var.repo_names
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  env = var.env
}

module "ecs" {
  source             = "./modules/ecs"
  env                = var.env
  aws_region         = "ap-south-1"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.alb.alb_sg_id
  target_group_blue_arn   = module.alb.blue_tg_arn
  execution_role_arn = data.aws_iam_role.ecs_execution.arn
  app_image          = module.ecr.repo_urls["${var.env}-app"]
  nginx_image        = module.ecr.repo_urls["${var.env}-nginx"]
}

module "codedeploy" {
  source = "./modules/codedeploy"

  env              = var.env

  # From ECS module — tells CodeDeploy which service to deploy into
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  # From ALB module — the listener CodeDeploy will flip during deployment
  alb_listener_arn = module.alb.alb_listener_arn

  # From ALB module — CodeDeploy needs names not ARNs for target groups
  blue_tg_name     = module.alb.blue_tg_name
  green_tg_name    = module.alb.green_tg_name
}
