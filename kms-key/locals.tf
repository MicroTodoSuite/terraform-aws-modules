# Local values of the kms-key module: the key's tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, var.additional_tags, { Name = var.key_name })
}
