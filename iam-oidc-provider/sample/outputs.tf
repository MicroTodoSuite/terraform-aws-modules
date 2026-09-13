# Outputs that prove the sample works.
output "provider_arn" {
  description = "ARN of the sample OIDC provider."
  value       = module.iam_oidc_provider.provider_arn
}
