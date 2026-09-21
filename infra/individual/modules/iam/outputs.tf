output "github_actions_role_arn" {
  description = "GitHub Actions Spring Batch デプロイ用 IAM Role ARN"
  value       = aws_iam_role.github_actions_spring_batch.arn
}
