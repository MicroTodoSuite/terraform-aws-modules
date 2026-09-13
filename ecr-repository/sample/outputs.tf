# Outputs that prove the sample works.
output "repository_urls" {
  description = "URL of each sample repository."
  value       = module.ecr_repository.repository_urls
}
