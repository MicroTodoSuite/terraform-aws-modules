# Outputs that prove the sample works.
output "queue_name" {
  description = "Name of the sample interruption queue."
  value       = module.karpenter_interruption.queue_name
}

output "rule_arns" {
  description = "ARN of each sample EventBridge rule."
  value       = module.karpenter_interruption.rule_arns
}
