# Outputs that prove the sample works.
output "key_arn" {
  description = "ARN of the sample key."
  value       = module.kms_key.key_arn
}
