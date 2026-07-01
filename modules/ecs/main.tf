resource "aws_security_group" "ecsg" {
  name   = "${var.env}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "ecs" {
  name = "${var.env}-cluster"

  tags = {
    Environment = var.env
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecsc" {
  cluster_name = aws_ecs_cluster.ecs.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "td" {
  family                   = "${var.env}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn = var.execution_role_arn
  container_definitions = jsonencode([
    {
      name      = "mongo"
      image     = "mongo:6"
      essential = true
      command = ["--wiredTigerCacheSizeGB", "0.25"]

      healthCheck = {
        command     = ["CMD-SHELL", "mongosh --eval \"db.adminCommand('ping')\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
      }
    }
    },
    {
      name      = "node_app"
      image     = var.app_image
      essential = true
      environment = [
        { name = "PORT",     value = "5000" },
      ]
      secrets = [
        {name = "MONGO_URI", valueFrom = var.secret_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
      }
    }

      dependsOn = [{ containerName = "mongo", condition = "HEALTHY" }]
    },
    {
      name      = "nginx"
      image     = var.nginx_image
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80 }]
      dependsOn = [{ containerName = "node_app", condition = "START" }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
      }
    }
    }

  ])

}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.env}"
  retention_in_days = 7
}


resource "aws_ecs_service" "service" {
  name            = "${var.env}-service"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecsg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "policy" {
  name               = "${var.env}-app-autoscaling_policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 50
  }
}
