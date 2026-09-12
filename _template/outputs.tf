# Outputs: granular IDs, ARNs, and names, each with a description (PC-IAC-007).
output "queue_arn" {
  description = "ARN of the queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL of the queue."
  value       = aws_sqs_queue.this.url
}

output "queue_name" {
  description = "Name of the queue."
  value       = aws_sqs_queue.this.name
}
