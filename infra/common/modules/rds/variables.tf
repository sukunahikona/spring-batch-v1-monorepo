variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for allowed access"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID for allowed access"
  type        = string
}

variable "db_username" {
  description = "Database username (from SSM Parameter Store)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password (from SSM Parameter Store)"
  type        = string
  sensitive   = true
}

variable "rds" {
  description = "RDS configuration"
  type = object({
    engine                   = string
    engine_version           = string
    instance_class           = string
    allocated_storage        = number
    storage_type             = string
    db_name                  = string
    backup_retention_days    = number
    multi_az                 = bool
    skip_final_snapshot      = bool
    snapshot_identifier_name = optional(string)  # 復元元のスナップショット名（nullの場合は新規作成）
  })
}
