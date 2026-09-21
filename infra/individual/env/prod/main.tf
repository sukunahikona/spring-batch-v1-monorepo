###############################################################################
# commonスタックのリソースをdataソースで参照
###############################################################################
data "aws_vpc" "this" {
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.project}-${var.environment}-private-*"]
  }
}

data "aws_db_instance" "this" {
  db_instance_identifier = "${var.project}-${var.environment}-rds"
}

###############################################################################
# Modules
###############################################################################
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment
}

module "iam" {
  source = "../../modules/iam"

  project            = var.project
  environment        = var.environment
  github_org         = var.github_org
  github_repo        = var.github_repo
  ecr_repository_arn = module.ecr.repository_arn
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  project                    = var.project
  environment                = var.environment
  cluster_arn                = module.ecs.cluster_arn
  task_definition_arn        = module.ecs.task_definition_arn
  private_subnet_ids         = module.ecs.private_subnet_ids
  ecs_task_security_group_id = module.ecs.ecs_task_security_group_id
}

module "ecs" {
  source = "../../modules/ecs"

  project            = var.project
  environment        = var.environment
  region             = var.region
  ecr_repository_url = module.ecr.repository_url
  vpc_id             = data.aws_vpc.this.id
  private_subnet_ids = data.aws_subnets.private.ids
  rds_endpoint       = data.aws_db_instance.this.address
  db_name            = data.aws_db_instance.this.db_name
  batch_cluster      = var.batch_cluster
}
