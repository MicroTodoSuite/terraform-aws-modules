# Terraform and provider requirements. Keep the minimum provider version compatible with every consuming root.
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
