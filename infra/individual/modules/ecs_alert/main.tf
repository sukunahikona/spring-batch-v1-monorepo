###############################################################################
# ECS タスクの異常終了を Slack へ通知する
#   EventBridge（ECS Task State Change）→ Lambda（メッセージ整形）→ Slack Incoming Webhook
# Webhook URL は SSM Parameter Store（SecureString）から Lambda が実行時に読み込む
###############################################################################
data "aws_caller_identity" "current" {}

locals {
  name             = "${var.project}-${var.environment}-ecs-task-alert"
  webhook_ssm_name = "/${var.project}/${var.environment}/slack/webhook_url"
  webhook_ssm_arn  = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.webhook_ssm_name}"
  lambda_log_group = "/aws/lambda/${local.name}"
}

###############################################################################
# Lambda
###############################################################################
data "archive_file" "notify" {
  type        = "zip"
  source_file = "${path.module}/lambda/notify.py"
  output_path = "${path.module}/lambda/notify.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group
  retention_in_days = 30

  tags = {
    Name = local.lambda_log_group
  }
}

resource "aws_iam_role" "lambda" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name}-lambda-role"
  }
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 自身のロググループへの出力のみ
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        # Slack の Webhook URL の読み取りのみ（SecureString は AWS 管理キーで復号される）
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = local.webhook_ssm_arn
      }
    ]
  })
}

resource "aws_lambda_function" "notify" {
  function_name = local.name
  description   = "ECSタスクの異常終了をSlackへ通知する"
  role          = aws_iam_role.lambda.arn

  runtime          = "python3.13"
  handler          = "notify.handler"
  filename         = data.archive_file.notify.output_path
  source_code_hash = data.archive_file.notify.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      SLACK_WEBHOOK_SSM_PARAM = local.webhook_ssm_name
      LOG_GROUP_NAME          = var.log_group_name
      CONTAINER_NAME          = var.container_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy.lambda]

  tags = {
    Name = local.name
  }
}

###############################################################################
# EventBridge ルール（対象クラスタで異常終了したタスクのみ）
#   - コンテナの exitCode が 0 以外で STOPPED
#   - 起動に失敗（stopCode = TaskFailedToStart。イメージ取得失敗など）
###############################################################################
resource "aws_cloudwatch_event_rule" "task_failure" {
  name        = "${local.name}-rule"
  description = "ECSタスクの異常終了（exitCode!=0 / 起動失敗）を検知する"

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail = {
      clusterArn = [var.cluster_arn]
      lastStatus = ["STOPPED"]
      "$or" = [
        { containers = { exitCode = [{ "anything-but" = 0 }] } },
        { stopCode = ["TaskFailedToStart"] }
      ]
    }
  })

  tags = {
    Name = "${local.name}-rule"
  }
}

resource "aws_cloudwatch_event_target" "notify" {
  rule = aws_cloudwatch_event_rule.task_failure.name
  arn  = aws_lambda_function.notify.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_failure.arn
}
