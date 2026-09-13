# Outputs that prove the sample works.
output "node_group_arn" {
  description = "ARN of the sample node group."
  value       = module.eks_node_group.node_group_arn
}
