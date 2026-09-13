# Outputs that prove the sample works.
output "cluster_endpoint" {
  description = "Endpoint of the sample cluster's Kubernetes API."
  value       = module.eks_cluster.cluster_endpoint
}

output "oidc_issuer_url" {
  description = "Issuer URL of the sample cluster's OpenID Connect provider."
  value       = module.eks_cluster.oidc_issuer_url
}
