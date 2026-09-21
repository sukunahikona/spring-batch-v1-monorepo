###############################################################################
# EventBridge Scheduler 用 IAM ロール（ECSタスクを起動する権限）
###############################################################################
resource "aws_iam_role" "eventbridge_scheduler" {
  name = "${var.project}-${var.environment}-eventbridge-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-eventbridge-scheduler-role"
  }
}

resource "aws_iam_policy" "eventbridge_scheduler" {
  name        = "${var.project}-${var.environment}-eventbridge-scheduler-policy"
  description = "EventBridge SchedulerがECSタスクを起動するための権限"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:RunTask"
        Resource = var.task_definition_arn
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_scheduler" {
  role       = aws_iam_role.eventbridge_scheduler.name
  policy_arn = aws_iam_policy.eventbridge_scheduler.arn
}

###############################################################################
# sampleJob スケジュール
###############################################################################
resource "aws_scheduler_schedule" "sample_job" {
  name        = "${var.project}-${var.environment}-sample-job-schedule"
  description = "Spring Batch sampleJob の定期実行スケジュール"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "rate(1 minute)"
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = var.cluster_arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    ecs_parameters {
      task_definition_arn = var.task_definition_arn
      task_count          = 1
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = var.private_subnet_ids
        security_groups  = [var.ecs_task_security_group_id]
        assign_public_ip = false
      }
    }

    input = jsonencode({
      containerOverrides = [
        {
          name = "spring-batch-app"
          environment = [
            {
              name  = "JOB_NAME"
              value = "sampleJob"
            }
          ]
        }
      ]
    })
  }
}

###############################################################################
# userFetchJob スケジュール
###############################################################################
resource "aws_scheduler_schedule" "user_fetch_job" {
  name        = "${var.project}-${var.environment}-user-fetch-job-schedule"
  description = "Spring Batch userFetchJob の定期実行スケジュール"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "rate(1 minute)"
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = var.cluster_arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    ecs_parameters {
      task_definition_arn = var.task_definition_arn
      task_count          = 1
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = var.private_subnet_ids
        security_groups  = [var.ecs_task_security_group_id]
        assign_public_ip = false
      }
    }

    input = jsonencode({
      containerOverrides = [
        {
          name = "spring-batch-app"
          environment = [
            {
              name  = "JOB_NAME"
              value = "userFetchJob"
            }
          ]
        }
      ]
    })
  }
}
