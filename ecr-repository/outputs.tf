# Outputs of the ecr-repository module, keyed like var.repositories.
output "repository_arns" {
  description = "ARN of each repository."
  value       = { for key, repository in aws_ecr_repository.this : key => repository.arn }
}

output "repository_urls" {
  description = "URL of each repository, for image references."
  value       = { for key, repository in aws_ecr_repository.this : key => repository.repository_url }
}

output "repository_names" {
  description = "Name of each repository."
  value       = { for key, repository in aws_ecr_repository.this : key => repository.name }
}
