# Terraform and provider requirements of the state-backend module.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.58.0" # blocked_encryption_types is documented from 6.58.0 on
      configuration_aliases = [aws.project]
    }
  }
}
