# Outputs that prove the sample works.
output "secret_arn" {
  description = "ARN of the sample secret."
  value       = module.secret.secret_arn
}
