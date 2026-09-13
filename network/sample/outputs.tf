# Outputs that prove the sample works.
output "vpc_id" {
  description = "ID of the sample VPC."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the sample's private subnets."
  value       = module.network.private_subnet_ids
}
