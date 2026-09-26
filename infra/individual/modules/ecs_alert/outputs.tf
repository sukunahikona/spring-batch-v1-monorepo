output "lambda_function_name" {
  description = "ECSタスク異常終了をSlackへ通知するLambdaの名前"
  value       = aws_lambda_function.notify.function_name
}

output "event_rule_name" {
  description = "ECSタスクの異常終了を検知するEventBridgeルールの名前"
  value       = aws_cloudwatch_event_rule.task_failure.name
}
