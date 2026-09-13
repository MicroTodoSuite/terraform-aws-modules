# Outputs of the eks-cluster module, consumed by the node groups, the OIDC provider, and the
# workload roots.
output "cluster_name" {
  description = "Name of the cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data of the cluster, for kubeconfig."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Amazon EKS platform version of the cluster."
  value       = aws_eks_cluster.this.platform_version
}

output "oidc_issuer_url" {
  description = "Issuer URL of the cluster's OpenID Connect provider, for the iam-oidc-provider module."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group Amazon EKS created; managed node groups use it for control-plane traffic."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "control_plane_log_group_name" {
  description = "Name of the control-plane log group."
  value       = aws_cloudwatch_log_group.control_plane.name
}

output "control_plane_log_group_arn" {
  description = "ARN of the control-plane log group."
  value       = aws_cloudwatch_log_group.control_plane.arn
}

output "access_entry_arns" {
  description = "ARN of each access entry, keyed like var.access_entries."
  value       = { for key, entry in aws_eks_access_entry.this : key => entry.access_entry_arn }
}

output "addon_arns" {
  description = "ARN of each managed add-on, keyed by add-on name."
  value       = merge({ for name, addon in aws_eks_addon.before_compute : name => addon.arn }, { for name, addon in aws_eks_addon.after_compute : name => addon.arn })
}
