# Terraform and provider requirements of the eks-node-group module. The provider floor is the
# release whose documentation was checked for every argument set here, node_repair_config
# included; no older release was verified.
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
