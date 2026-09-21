output "scheduler_role_arn" {
  description = "EventBridge Scheduler IAM role ARN"
  value       = aws_iam_role.eventbridge_scheduler.arn
}

output "sample_job_schedule_arn" {
  description = "sampleJob スケジュール ARN"
  value       = aws_scheduler_schedule.sample_job.arn
}

output "user_fetch_job_schedule_arn" {
  description = "userFetchJob スケジュール ARN"
  value       = aws_scheduler_schedule.user_fetch_job.arn
}
