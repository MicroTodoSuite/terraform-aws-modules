# Local values of the iam-role module: the role's tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, var.additional_tags, { Name = var.role_name })
}
