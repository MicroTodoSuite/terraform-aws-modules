# Name construction for the transit-egress sample: a shared hub with three full-profile spokes.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  hub_vpc = {
    id                    = var.hub_vpc_id
    cidr_block            = "10.50.0.0/16"
    attachment_subnet_ids = var.hub_attachment_subnet_ids
    public_route_table_id = var.hub_public_route_table_id
  }

  spokes = {
    fdev = { vpc_cidr = "10.20.0.0/16", route_table_name = "${local.governance_prefix}-rtb-tgwfdev" }
    fstg = { vpc_cidr = "10.21.0.0/16", route_table_name = "${local.governance_prefix}-rtb-tgwfstg" }
    fprd = { vpc_cidr = "10.22.0.0/16", route_table_name = "${local.governance_prefix}-rtb-tgwfprd" }
  }
}
