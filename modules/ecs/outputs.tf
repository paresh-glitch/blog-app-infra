output "cluster_name" {
  value = aws_ecs_cluster.ecs.name
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_td" {
  value = aws_ecs_task_definition.td.family
}
