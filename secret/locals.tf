# Local values of the secret module: the secret's tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, var.additional_tags, { Name = var.secret_name })
}
