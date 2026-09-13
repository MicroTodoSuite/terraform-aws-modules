# Outputs of the eks-node-group module. node_group_arn feeds the eks-cluster module's
# compute_ready, so add-ons that need nodes wait for this group.
output "node_group_arn" {
  description = "ARN of the node group."
  value       = aws_eks_node_group.this.arn
}

output "node_group_id" {
  description = "ID of the node group: the cluster name and the node group name separated by a colon."
  value       = aws_eks_node_group.this.id
}

output "node_group_name" {
  description = "Physical name of the node group: the standard name and a unique suffix."
  value       = aws_eks_node_group.this.node_group_name
}

output "launch_template_id" {
  description = "ID of the node group's launch template."
  value       = aws_launch_template.this.id
}

output "launch_template_version" {
  description = "Version of the launch template the node group runs."
  value       = aws_launch_template.this.latest_version
}

output "autoscaling_group_names" {
  description = "Names of the Auto Scaling groups Amazon EKS created for the node group."
  value       = flatten([for resource in aws_eks_node_group.this.resources : resource.autoscaling_groups[*].name])
}
