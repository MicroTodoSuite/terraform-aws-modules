# Outputs that prove the sample works.
output "bucket_name" {
  description = "Full name of the sample state bucket."
  value       = module.state_backend.bucket_name
}

output "kms_alias_name" {
  description = "Alias of the sample state encryption key."
  value       = module.state_backend.kms_alias_name
}
