variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "target_group_arn" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}

variable "app_image" {
  type = string
}
variable "nginx_image" {
  type = string
}
variable "alb_sg_id" {
  type = string
}

variable "secret_arn" {
  type = string
}
