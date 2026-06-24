output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "alb_sg_id" {
  value = aws_security_group.lb_sg.id
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "alb_listener_arn" {
  value = aws_lb_listener.this.arn
}

output "alb_name" {
  value = aws_lb.alb.name
}
