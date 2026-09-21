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

variable "ecr_repository_url" {
  description = "ECR repository URL for Spring Batch app"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS tasks"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "rds_endpoint" {
  description = "RDS endpoint for Spring Batch DB connection"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "springbatchdb"
}

variable "batch_cluster" {
  description = "ECS Spring Batch クラスタ設定"
  type = object({
    task_cpu    = number
    task_memory = number
  })
}
