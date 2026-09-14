# Outputs of the CloudTrail trail module (PC-IAC-007).
output "trail_arn" {
  description = "ARN of the trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_name" {
  description = "Name of the trail."
  value       = aws_cloudtrail.this.name
}

output "bucket_name" {
  description = "Full name of the log bucket, with the account ID suffix."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the log bucket."
  value       = aws_s3_bucket.this.arn
}
