variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod, stg, dev)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr                 = string
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
    availability_zones   = list(string)
  })
}

variable "ec2" {
  description = "EC2 instances configuration"
  type = object({
    public_bastion = object({
      instance_type     = string
      ssh_key_name      = string
      allowed_ssh_cidrs = list(string)
    })
  })
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
