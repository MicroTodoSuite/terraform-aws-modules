# Terraform and provider requirements of the eks-cluster module. The provider floor is the
# release whose documentation was checked for every argument set here, deletion_protection
# and upgrade_policy included; no older release was verified.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.64.0"
      configuration_aliases = [aws.project]
    }
  }
}
