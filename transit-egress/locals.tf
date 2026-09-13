# Local values of the transit-egress module: the tags every resource carries.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  base_tags = merge(local.governance_tags, var.additional_tags)
}
