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

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "batch_cluster" {
  description = "ECS Spring Batch クラスタ設定"
  type = object({
    task_cpu    = number
    task_memory = number
  })
}

variable "batch_schedule_state" {
  description = "EventBridge Scheduler の定期実行の状態（ENABLED / DISABLED）"
  type        = string
  default     = "ENABLED"
}

variable "github_org_id" {
  description = "GitHub organization or user numeric ID (OIDCトークンのsubに含まれる不変ID)"
  type        = string
}

variable "github_repo_id" {
  description = "GitHub repository numeric ID (OIDCトークンのsubに含まれる不変ID)"
  type        = string
}

variable "github_environment" {
  description = "GitHub Environments の名前（デプロイ用ワークフローのジョブで environment: に指定する名前）"
  type        = string
}
