variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_arn" {
  description = "監視対象の ECS クラスタ ARN"
  type        = string
}

variable "container_name" {
  description = "バッチのコンテナ名（通知にログの場所を載せるため）"
  type        = string
}

variable "log_group_name" {
  description = "バッチタスクの CloudWatch Logs ロググループ名（通知にログの場所を載せるため）"
  type        = string
}
