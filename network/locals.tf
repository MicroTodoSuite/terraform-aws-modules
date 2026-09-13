# Local values of the network module: governance tags and the subnets grouped by tier and egress.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  base_tags = merge(local.governance_tags, var.additional_tags)

  public_subnets          = { for key, subnet in var.subnets : key => subnet if subnet.tier == "public" }
  private_subnets         = { for key, subnet in var.subnets : key => subnet if subnet.tier == "private" }
  nat_private_subnets     = { for key, subnet in local.private_subnets : key => subnet if subnet.egress == "nat" }
  transit_private_subnets = { for key, subnet in local.private_subnets : key => subnet if subnet.egress == "transit" }
}
