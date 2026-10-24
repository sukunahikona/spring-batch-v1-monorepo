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
# タスクロールの権限（Fluent Bit サイドカーのログ出力と、init による設定の取得。バケットは s3.tf）
###############################################################################
resource "aws_iam_policy" "ecs_task_logs" {
  name        = "${var.project}-${var.environment}-ecs-task-logs-policy"
  description = "Fluent Bit サイドカーが CloudWatch Logs と S3 にログを出力し、S3 から設定を取得するための権限"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = "${aws_cloudwatch_log_group.spring_batch.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload",
        ]
        Resource = "${aws_s3_bucket.batch_logs.arn}/spring-batch/*"
      },
      {
        # init プロセスが設定ファイルを取得する
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.batch_logs.arn}/fluent-bit/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.batch_logs.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_logs" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}
