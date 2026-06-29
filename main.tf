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
  target_group_arn   = module.alb.target_group_arn
  execution_role_arn = data.aws_iam_role.ecs_execution.arn
  app_image          = module.ecr.repo_urls["${var.env}-app"]
  nginx_image        = module.ecr.repo_urls["${var.env}-nginx"]
  secret_arn = module.secrets_manager.secret_arn
}

module "secrets_manager" {
  source      = "./modules/secrets_manager"
  env         = var.env
  secret_name = "mini-blog/prod/mongo-uri"
}

resource "aws_iam_role_policy" "secrets_manager_read" {
  name = "secrets-manager-read-${var.env}"
  role = data.aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = module.secrets_manager.secret_arn
      }
    ]
  })
}
