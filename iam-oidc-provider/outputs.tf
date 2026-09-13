# Outputs of the iam-oidc-provider module, consumed by the roles that trust it.
output "provider_arn" {
  description = "ARN of the OIDC provider, the Federated principal in trust policies."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "provider_url" {
  description = "Issuer URL of the provider."
  value       = aws_iam_openid_connect_provider.this.url
}
