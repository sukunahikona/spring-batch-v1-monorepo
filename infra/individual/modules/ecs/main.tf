###############################################################################
# CloudWatch Log Group
###############################################################################
resource "aws_cloudwatch_log_group" "spring_batch" {
  name              = "/ecs/${var.project}-${var.environment}-spring-batch"
  retention_in_days = 30

  tags = {
    Name = "/ecs/${var.project}-${var.environment}-spring-batch"
  }
}

###############################################################################
# ECS クラスタ
###############################################################################
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project}-${var.environment}-cluster"
  }
}

###############################################################################
# ECS タスク実行ロール（ECR pull・CloudWatch Logs書き込み・SSM取得）
###############################################################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task-execution-role"
  }
}

# AWSマネージドポリシー（ECR pull・CloudWatch Logs書き込み）
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SSM Parameter Store からシークレット取得権限
resource "aws_iam_policy" "ecs_task_execution_ssm" {
  name        = "${var.project}-${var.environment}-ecs-task-execution-ssm-policy"
  description = "ECSタスク実行ロールがSSM Parameter Storeからシークレットを取得するための権限"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
        ]
        Resource = "arn:aws:ssm:${var.region}:*:parameter/${var.project}/${var.environment}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm.arn
}

###############################################################################
# ECS タスクロール（コンテナ内アプリが使用するロール）
###############################################################################
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task-role"
  }
}

###############################################################################
# ECS タスク用セキュリティグループ
###############################################################################
resource "aws_security_group" "ecs_task" {
  name        = "${var.project}-${var.environment}-ecs-task-sg"
  description = "Security group for ECS Spring Batch tasks"
  vpc_id      = var.vpc_id

  # アウトバウンド（ECR pull・RDS接続・SSM・CloudWatch Logs）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecs-task-sg"
  }
}

###############################################################################
# ECS タスク定義（Spring Batch）
###############################################################################
resource "aws_ecs_task_definition" "spring_batch" {
  family                   = "${var.project}-${var.environment}-spring-batch"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.batch_cluster.task_cpu
  memory                   = var.batch_cluster.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = templatefile("${path.module}/tasks/spring-batch.json.tpl", {
    ecr_repository_url = var.ecr_repository_url
    rds_endpoint       = var.rds_endpoint
    db_name            = var.db_name
    project            = var.project
    environment        = var.environment
    region             = var.region
    log_group_name     = aws_cloudwatch_log_group.spring_batch.name
  })

  tags = {
    Name = "${var.project}-${var.environment}-spring-batch"
  }
}
