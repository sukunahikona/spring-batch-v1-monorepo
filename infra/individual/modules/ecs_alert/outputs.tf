output "event_rule_name" {
  description = "ECSタスクの異常を検知するEventBridgeルールの名前"
  value       = aws_cloudwatch_event_rule.task_failure.name
}

output "api_destination_arn" {
  description = "Slackへ通知するAPI destinationのARN"
  value       = aws_cloudwatch_event_api_destination.slack.arn
}
