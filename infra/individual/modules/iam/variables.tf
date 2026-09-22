variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
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

variable "ecr_repository_arn" {
  description = "ECR repository ARN to allow push access"
  type        = string
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
  description = "GitHub Environments の名前。このEnvironmentを使うジョブだけがロールを引き受けられる"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS cluster ARN (単発タスクの起動を許可する対象)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_task_definition_family" {
  description = "ECS task definition family (単発タスクの起動を許可する対象)"
  type        = string
}

variable "ecs_pass_role_arns" {
  description = "ECSタスクへ渡すことを許可するIAMロールのARN(実行ロール・タスクロール)"
  type        = list(string)
}

variable "ecs_log_group_arn" {
  description = "バッチタスクのCloudWatch Logsロググループ ARN (ログ参照を許可する対象)"
  type        = string
}
