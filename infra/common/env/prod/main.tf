###############################################################################
# SSM Parameter Storeからの読み込み
###############################################################################
data "aws_ssm_parameter" "rds_username" {
  name = "/${var.project}/${var.environment}/rds/username"
}

data "aws_ssm_parameter" "rds_password" {
  name            = "/${var.project}/${var.environment}/rds/password"
  with_decryption = true
}

###############################################################################
# Modules
###############################################################################
module "iam" {
  source = "../../modules/iam"
}

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc         = var.vpc
  ec2         = var.ec2
}

module "rds" {
  source = "../../modules/rds"

  project                   = var.project
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  private_subnet_cidrs      = var.vpc.private_subnet_cidrs
  bastion_security_group_id = module.vpc.bastion_security_group_id
  rds                       = var.rds
  db_username               = data.aws_ssm_parameter.rds_username.value
  db_password               = data.aws_ssm_parameter.rds_password.value
}
