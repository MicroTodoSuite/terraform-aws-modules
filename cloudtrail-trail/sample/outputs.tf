# Outputs that prove the sample works.
output "trail_arn" {
  description = "ARN of the sample trail."
  value       = module.cloudtrail_trail.trail_arn
}

output "bucket_name" {
  description = "Full name of the sample log bucket."
  value       = module.cloudtrail_trail.bucket_name
}
