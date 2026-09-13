# Outputs that prove the sample works.
output "security_group_id" {
  description = "ID of the sample group."
  value       = module.security_group.security_group_id
}
