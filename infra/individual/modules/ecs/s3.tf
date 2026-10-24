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
