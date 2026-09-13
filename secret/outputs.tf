# Outputs of the secret module. The value is never returned (PC-IAC-016).
output "secret_arn" {
  description = "ARN of the secret, for reader policies."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the secret, for ExternalSecret references."
  value       = aws_secretsmanager_secret.this.name
}
