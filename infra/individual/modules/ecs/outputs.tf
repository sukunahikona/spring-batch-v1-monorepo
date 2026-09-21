output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.spring_batch.arn
}

output "task_definition_family" {
  description = "ECS task definition family name"
  value       = aws_ecs_task_definition.spring_batch.family
}

output "task_execution_role_arn" {
  description = "ECS task execution IAM role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_security_group_id" {
  description = "ECS task security group ID"
  value       = aws_security_group.ecs_task.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS tasks"
  value       = var.private_subnet_ids
}
