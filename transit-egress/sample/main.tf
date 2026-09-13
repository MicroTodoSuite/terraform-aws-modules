# The transit-egress sample: one call of the module, fed from locals.
module "transit_egress" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client               = var.client
  project              = var.project
  environment          = var.environment
  transit_gateway_name = "${local.governance_prefix}-tgw-sample"
  hub_attachment_name  = "${local.governance_prefix}-tgwa-sample"
  hub_route_table_name = "${local.governance_prefix}-rtb-tgwhub"
  hub_vpc              = local.hub_vpc
  spokes               = local.spokes
}
