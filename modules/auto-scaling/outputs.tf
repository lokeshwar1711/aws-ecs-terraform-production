# Outputs for Auto Scaling Module

output "autoscaling_target_arn" {
  description = "ARN of the autoscaling target"
  value       = aws_appautoscaling_target.ecs_target.arn
}

output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU scaling policy"
  value       = aws_appautoscaling_policy.cpu_policy.arn
}

output "memory_scaling_policy_arn" {
  description = "ARN of the memory scaling policy"
  value       = aws_appautoscaling_policy.memory_policy.arn
}

output "request_count_scaling_policy_arn" {
  description = "ARN of the request count scaling policy"
  value       = var.enable_request_count_scaling ? aws_appautoscaling_policy.request_count_policy[0].arn : null
}

output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "memory_high_alarm_arn" {
  description = "ARN of the memory high alarm"
  value       = aws_cloudwatch_metric_alarm.memory_high.arn
}

output "service_count_low_alarm_arn" {
  description = "ARN of the service count low alarm"
  value       = aws_cloudwatch_metric_alarm.service_count_low.arn
}

output "scale_up_scheduled_action_arn" {
  description = "ARN of the scale up scheduled action"
  value       = var.enable_scheduled_scaling ? aws_appautoscaling_scheduled_action.scale_up[0].arn : null
}

output "scale_down_scheduled_action_arn" {
  description = "ARN of the scale down scheduled action"
  value       = var.enable_scheduled_scaling ? aws_appautoscaling_scheduled_action.scale_down[0].arn : null
}