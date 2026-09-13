# Terraform and provider requirements of the network module. Cross-variable validation needs Terraform 1.9 or later.
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
