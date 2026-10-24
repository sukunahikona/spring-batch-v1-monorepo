###############################################################################
# ECS タスクの起動失敗・異常終了を Slack へ通知する
#   EventBridge ルール（ECS Task State Change）→ API destination → Slack Incoming Webhook
# 起動後のジョブの例外はアプリ側（SlackJobExecutionListener）が通知する。
# ここでは、アプリが通知できない「起動失敗」や「起動直後のクラッシュ」を拾う。
###############################################################################

# Slack の Webhook URL（アプリと同じ SSM パラメータ）。
# API destination のエンドポイントとして渡すため、tfstate に含まれる（state の S3 は閲覧者を限定している）
data "aws_ssm_parameter" "slack_webhook_url" {
  name            = "/${var.project}/${var.environment}/slack/webhook_url"
  with_decryption = true
}

locals {
  name = "${var.project}-${var.environment}-ecs-task-alert"
}

###############################################################################
# API destination（Slack Incoming Webhook）
###############################################################################
# Slack の Webhook は認証不要だが、API destination には Connection が必須のためダミーのキーを設定する
resource "aws_cloudwatch_event_connection" "slack" {
  name               = "${local.name}-slack"
  description        = "Slack Incoming Webhook（認証不要のためダミーのキー）"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "x-dummy"
      value = "dummy"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "slack" {
  name                             = "${local.name}-slack"
  description                      = "ECSタスクの異常をSlackへ通知する"
  connection_arn                   = aws_cloudwatch_event_connection.slack.arn
  invocation_endpoint              = data.aws_ssm_parameter.slack_webhook_url.value
  http_method                      = "POST"
  invocation_rate_limit_per_second = 5
}

###############################################################################
# EventBridge が API destination を呼び出すための IAM ロール
###############################################################################
resource "aws_iam_role" "eventbridge" {
  name = "${local.name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name}-eventbridge-role"
  }
}

resource "aws_iam_role_policy" "eventbridge" {
  name = "${local.name}-eventbridge-policy"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "events:InvokeApiDestination"
        Resource = aws_cloudwatch_event_api_destination.slack.arn
      }
    ]
  })
}

###############################################################################
# EventBridge ルール
#   対象クラスタで、JOB_NAME を指定して起動したタスク（定期実行）のうち、
#   - コンテナの exitCode が 0 以外で STOPPED（起動直後のクラッシュなど）
#   - 起動に失敗（stopCode = TaskFailedToStart。イメージ取得失敗など）
#   したものだけを対象にする。CI の DB 初期化タスク（JOB_NAME なし）は CI 側で失敗が分かるため対象外。
###############################################################################
resource "aws_cloudwatch_event_rule" "task_failure" {
  name        = "${local.name}-rule"
  description = "ECSタスクの起動失敗・異常終了（exitCode!=0）を検知する"

  event_pattern = jsonencode({
    source        = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail = {
      clusterArn = [var.cluster_arn]
      lastStatus = ["STOPPED"]
      overrides = {
        containerOverrides = {
          environment = { name = ["JOB_NAME"] }
        }
      }
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

resource "aws_cloudwatch_event_target" "slack" {
  rule     = aws_cloudwatch_event_rule.task_failure.name
  arn      = aws_cloudwatch_event_api_destination.slack.arn
  role_arn = aws_iam_role.eventbridge.arn

  # 通知の失敗は、一定時間だけ再試行する
  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 3600
  }

  input_transformer {
    # JOB_NAME は、定期実行の上書き設定（JOB_NAME のみ）の先頭にある前提で位置を指定している
    input_paths = {
      job      = "$.detail.overrides.containerOverrides[0].environment[0].value"
      stopCode = "$.detail.stopCode"
      reason   = "$.detail.stoppedReason"
      exitCode = "$.detail.containers[0].exitCode"
      taskArn  = "$.detail.taskArn"
      time     = "$.time"
    }

    input_template = <<-EOT
      {"text": ":rotating_light: ECSタスクの起動失敗・異常終了\n• バッチ: `<job>`\n• 停止コード: `<stopCode>`\n• exitCode: `<exitCode>`\n• 理由: <reason>\n• タスク: <taskArn>\n• 時刻: <time>\n• ログ: `${var.log_group_name}`"}
    EOT
  }
}
