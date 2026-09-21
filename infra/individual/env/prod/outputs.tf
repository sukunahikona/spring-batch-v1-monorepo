###############################################################################
# ECR Outputs
###############################################################################
output "ecr_repository_url" {
  description = "ECR repository URL for spring-batch-app-v1"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name for spring-batch-app-v1"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN for spring-batch-app-v1"
  value       = module.ecr.repository_arn
}

###############################################################################
# IAM Outputs
###############################################################################
output "github_actions_role_arn" {
  description = "GitHub Actions ECR プッシュ用 IAM Role ARN"
  value       = module.iam.github_actions_role_arn
}

###############################################################################
# ECS Outputs
###############################################################################
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs.task_definition_arn
}

output "ecs_task_security_group_id" {
  description = "ECS task security group ID（手動実行時に使用）"
  value       = module.ecs.ecs_task_security_group_id
}

output "ecs_private_subnet_ids" {
  description = "ECS task が起動するプライベートサブネットID（手動実行時に使用）"
  value       = module.ecs.private_subnet_ids
}
