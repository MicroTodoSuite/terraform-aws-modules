# Outputs: what the cluster's Karpenter release and its operators need (PC-IAC-007).
output "queue_name" {
  description = "Name of the interruption queue, the value Karpenter's --interruption-queue setting takes."
  value       = aws_sqs_queue.this.name
}

output "queue_arn" {
  description = "ARN of the interruption queue, which the Karpenter controller role reads."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL of the interruption queue."
  value       = aws_sqs_queue.this.url
}

output "rule_arns" {
  description = "ARN of each EventBridge rule, keyed by event: scheduled_change, spot_interruption, rebalance, instance_state_change, and capacity_reservation."
  value       = { for key, rule in aws_cloudwatch_event_rule.this : key => rule.arn }
}
