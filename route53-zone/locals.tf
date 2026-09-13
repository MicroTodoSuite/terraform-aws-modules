# Local values of the route53-zone module: the zone's tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, var.additional_tags, { Name = var.standard_name })
}
