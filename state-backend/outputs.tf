# Outputs of the state-backend module, consumed by the backend configuration of every root.
output "bucket_name" {
  description = "Full name of the state bucket, account suffix included."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.this.arn
}

output "kms_key_arn" {
  description = "ARN of the key that encrypts state and lock files."
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "ID of the key that encrypts state and lock files."
  value       = aws_kms_key.this.key_id
}

output "kms_alias_name" {
  description = "Alias of the state encryption key."
  value       = aws_kms_alias.this.name
}
