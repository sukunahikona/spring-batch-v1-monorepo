terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}

module "s3" {
  source = "../../../modules/s3"

  project           = var.project
  environment       = var.environment
  state_bucket_name = var.state_bucket_name
}

module "ssm_parameter" {
  source = "../../../modules/ssm_parameter"

  project     = var.project
  environment = var.environment

  parameters = {
    "rds/username" = {
      value       = var.rds_credentials.username
      type        = "String"
      description = "RDS database username"
    }
    "rds/password" = {
      value       = var.rds_credentials.password
      type        = "SecureString"
      description = "RDS database password"
    }
  }
}
