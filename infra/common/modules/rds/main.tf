###############################################################################
# DB Subnet Group (Multi-AZ: ap-northeast-1a, 1c)
###############################################################################
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  }
}

###############################################################################
# RDS Security Group (PostgreSQL port 5432)
###############################################################################
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL access from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  ingress {
    description     = "PostgreSQL access from bastion host"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-sg"
  }
}

###############################################################################
# RDS PostgreSQL Instance (Multi-AZ構成)
###############################################################################
resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-rds"

  # エンジン設定（PostgreSQL 16系）
  engine         = var.rds.engine
  engine_version = var.rds.engine_version
  auto_minor_version_upgrade = true

  # インスタンス設定
  instance_class = var.rds.instance_class

  # ストレージ設定
  allocated_storage = var.rds.allocated_storage
  storage_type      = var.rds.storage_type
  storage_encrypted = true

  # スナップショットから復元（snapshot_identifier_nameが指定されている場合）
  snapshot_identifier = var.rds.snapshot_identifier_name

  # データベース設定
  # スナップショットから復元する場合はdb_nameをnullに設定（RDSの仕様）
  db_name  = var.rds.snapshot_identifier_name != null ? null : var.rds.db_name
  username = var.db_username
  password = var.db_password

  # ネットワーク設定
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # マルチAZ設定（1a, 1c）
  multi_az = var.rds.multi_az

  # バックアップ設定
  backup_retention_period = var.rds.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # スナップショット設定
  skip_final_snapshot       = var.rds.skip_final_snapshot
  final_snapshot_identifier = var.rds.skip_final_snapshot ? null : "${var.project}-${var.environment}-rds-final-snapshot-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  # 削除保護
  deletion_protection = false

  # PostgreSQL用CloudWatch Logsエクスポート
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # パラメータグループ（PostgreSQL 16用）
  parameter_group_name = aws_db_parameter_group.postgres.name

  # パフォーマンスインサイト
  performance_insights_enabled = true

  tags = {
    Name = "${var.project}-${var.environment}-rds-postgres"
  }
}

###############################################################################
# DB Parameter Group
###############################################################################
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project}-${var.environment}-postgres${split(".", var.rds.engine_version)[0]}-params"
  family = "postgres${split(".", var.rds.engine_version)[0]}"

  # PostgreSQLの設定例（必要に応じてカスタマイズ）
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = {
    Name = "${var.project}-${var.environment}-postgres${split(".", var.rds.engine_version)[0]}-params"
  }
}
