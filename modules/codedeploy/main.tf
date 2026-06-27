# ------------------------------------------------------------
# 1. CodeDeploy Application
#    Just a named bucket that groups deployment groups.
#    compute_platform = "ECS" tells AWS this is for containers.
# ------------------------------------------------------------
resource "aws_codedeploy_app" "this" {
  name             = "${var.env}-app"
  compute_platform = "ECS"
}

# ------------------------------------------------------------
# 2. IAM Role for CodeDeploy
#    CodeDeploy needs permission to talk to ECS, ALB, and
#    CloudWatch on your behalf. This is the role it wears.
# ------------------------------------------------------------
resource "aws_iam_role" "codedeploy" {
  name = "${var.env}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  # AWS managed policy — covers everything CodeDeploy needs:
  # ECS task registration, ALB listener modification, CloudWatch logs
}

# ------------------------------------------------------------
# 3. Deployment Group
#    This is the actual config CodeDeploy uses at deploy time.
#    It wires together: ECS service + ALB listener + both TGs.
# ------------------------------------------------------------
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${var.env}-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn

  # Blue/green with actual traffic control (not just task swap)
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Which ECS cluster + service to deploy into
  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  # Wires the ALB listener to both target groups.
  # CodeDeploy will:
  # 1. Register new tasks into green TG
  # 2. Wait for health checks to pass
  # 3. Flip the listener to send traffic to green
  # 4. Wait 5 mins then terminate blue tasks
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }
      target_group {
        name = var.blue_tg_name
      }
      target_group {
        name = var.green_tg_name
      }
    }
  }

  blue_green_deployment_config {
    # After traffic shifts to green, keep blue tasks alive
    # for 5 minutes in case you need instant rollback,
    # then terminate them automatically.
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    # Once green tasks are healthy, proceed automatically.
    # Alternative: STOP_DEPLOYMENT (manual approval required)
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  # Flip 100% of traffic to green in one shot.
  # Alternatives exist for canary/linear rollouts but
  # AllAtOnce is simplest to start with.
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
}
