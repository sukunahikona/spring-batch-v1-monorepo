###############################################################################
# ログ保管用 S3 バケット（Fluent Bit サイドカーが出力する）
#   CloudWatch Logs は直近30日だけ保持し、S3 は batch_logs_retention_days（既定365日）で削除する。
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

# バッチのログ（spring-batch/ 配下）だけを一定期間で削除する。
# Fluent Bit の設定（fluent-bit/ 配下）は、起動のたびに取得するため対象に含めない。
resource "aws_s3_bucket_lifecycle_configuration" "batch_logs" {
  bucket = aws_s3_bucket.batch_logs.id

  rule {
    id     = "expire-batch-logs"
    status = "Enabled"

    filter {
      prefix = "spring-batch/"
    }

    expiration {
      days = var.batch_logs_retention_days
    }

    # 失敗したアップロードの断片が残り続けないようにする
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

###############################################################################
# Fluent Bit の追加設定（S3 への出力）
#   Fargate では S3 上の設定ファイルを直接指定できないため、init イメージが起動時に取得する。
#   CloudWatch Logs への出力は、タスク定義の logConfiguration から FireLens が生成する。
###############################################################################
locals {
  fluent_bit_s3_output_conf = templatefile("${path.module}/tasks/conf/fluent-bit-s3-output.conf.tpl", {
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
