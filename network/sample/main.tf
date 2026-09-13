# The network sample: one call of the module, fed from locals.
module "network" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client                  = var.client
  project                 = var.project
  environment             = var.environment
  vpc                     = local.vpc
  internet_gateway_name   = "${local.governance_prefix}-igw-sample"
  public_route_table_name = "${local.governance_prefix}-rtb-public"
  subnets                 = local.subnets
  nat_gateways            = local.nat_gateways
  transit_gateway_id      = ""
  transit_attachment      = null
  flow_log                = local.flow_log
}
