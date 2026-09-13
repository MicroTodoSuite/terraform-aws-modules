# Terraform and provider requirements of the secret module. Write-only arguments need Terraform 1.11.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.project]
    }
  }
}
