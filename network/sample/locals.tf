# Name construction for the network sample: two zones, one NAT gateway.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  vpc = { name = "${local.governance_prefix}-vpc-sample", cidr_block = "10.90.0.0/16" }

  subnets = {
    puba  = { name = "${local.governance_prefix}-sub-puba", availability_zone = "${var.region}a", cidr_block = "10.90.0.0/24", tier = "public" }
    pubb  = { name = "${local.governance_prefix}-sub-pubb", availability_zone = "${var.region}b", cidr_block = "10.90.1.0/24", tier = "public" }
    priva = { name = "${local.governance_prefix}-sub-priva", availability_zone = "${var.region}a", cidr_block = "10.90.16.0/20", tier = "private", route_table_name = "${local.governance_prefix}-rtb-priva", egress = "nat", nat_gateway_key = "a" }
    privb = { name = "${local.governance_prefix}-sub-privb", availability_zone = "${var.region}b", cidr_block = "10.90.32.0/20", tier = "private", route_table_name = "${local.governance_prefix}-rtb-privb", egress = "nat", nat_gateway_key = "a" }
  }

  nat_gateways = {
    a = { name = "${local.governance_prefix}-nat-a", eip_name = "${local.governance_prefix}-eip-a", subnet_key = "puba" }
  }

  flow_log = {
    name                    = "${local.governance_prefix}-fl-sample"
    log_group_name          = "/aws/vpc-flow-logs/${local.governance_prefix}-vpc-sample"
    log_group_standard_name = "${local.governance_prefix}-cwl-sample"
    retention_in_days       = 30
    kms_key_arn             = var.flow_log_kms_key_arn
    iam_role_arn            = var.flow_log_role_arn
  }
}
