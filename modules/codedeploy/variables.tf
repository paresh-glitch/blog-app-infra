variable "env" {
  type = string
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster — CodeDeploy needs this to find your service"
}

variable "ecs_service_name" {
  type        = string
  description = "Name of the ECS service — must match aws_ecs_service.service.name exactly"
}

variable "alb_listener_arn" {
  type        = string
  description = "ARN of the ALB listener CodeDeploy will flip during deployment"
}

variable "blue_tg_name" {
  type        = string
  description = "Name of blue target group — CodeDeploy needs names not ARNs here"
}

variable "green_tg_name" {
  type        = string
  description = "Name of green target group"
}
