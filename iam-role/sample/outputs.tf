# Outputs that prove the sample works.
output "role_arn" {
  description = "ARN of the sample role."
  value       = module.iam_role.role_arn
}
