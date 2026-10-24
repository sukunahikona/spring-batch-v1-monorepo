###############################################################################
# ログ保管用 S3 バケット（Fluent Bit サイドカーが出力する）
#   CloudWatch Logs は直近30日だけ保持し、S3 は保持期間を限定しない（ライフサイクルルールなし）。
###############################################################################
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "batch_logs" {
  # バケット名はグローバルで一意にする必要があるため、アカウント ID を付ける
  bucket = "${var.project}-${var.environment}-batch-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project}-${var.environment}-batch-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "batch_logs" {
  bucket = aws_s3_bucket.batch_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "batch_logs" {
  bucket = aws_s3_bucket.batch_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###############################################################################
# Fluent Bit の追加設定（S3 への出力）
#   Fargate では S3 上の設定ファイルを直接指定できないため、init イメージが起動時に取得する。
#   CloudWatch Logs への出力は、タスク定義の logConfiguration から FireLens が生成する。
###############################################################################
locals {
  fluent_bit_s3_output_conf = templatefile("${path.module}/tasks/fluent-bit-s3-output.conf.tpl", {
    region = var.region
    bucket = aws_s3_bucket.batch_logs.id
  })
}

resource "aws_s3_object" "fluent_bit_s3_output" {
  bucket  = aws_s3_bucket.batch_logs.id
  key     = "fluent-bit/s3-output.conf"
  content = local.fluent_bit_s3_output_conf
  etag    = md5(local.fluent_bit_s3_output_conf)
}

###############################################################################
# タスクロールの権限（Fluent Bit のログ出力と、init による設定の取得）
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
