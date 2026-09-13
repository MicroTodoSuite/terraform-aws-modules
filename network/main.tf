# One VPC with public and private subnets, an internet gateway, optional NAT gateways, and
# encrypted flow logs. Routes are separate aws_route resources, never in-line blocks, so the
# two styles cannot overwrite each other. This module owns the VPC types (iac-contracts.json).
resource "aws_vpc" "this" {
  provider = aws.project

  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.base_tags, { Name = var.vpc.name })
}

resource "aws_internet_gateway" "this" {
  provider = aws.project

  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = var.internet_gateway_name })
}

resource "aws_subnet" "this" {
  for_each = var.subnets
  provider = aws.project

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false
  tags                    = merge(local.base_tags, each.value.tags, { Name = each.value.name })
}

resource "aws_route_table" "public" {
  provider = aws.project

  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = var.public_route_table_name })
}

resource "aws_route" "public_internet" {
  provider = aws.project

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets
  provider = aws.project

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "this" {
  for_each = var.nat_gateways
  provider = aws.project

  domain = "vpc"
  tags   = merge(local.base_tags, { Name = each.value.eip_name })

  # An Elastic IP for a NAT gateway needs the internet gateway attached first; the
  # provider documentation asks for this ordering, which no attribute expresses.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = var.nat_gateways
  provider = aws.project

  allocation_id = aws_eip.this[each.key].id
  subnet_id     = aws_subnet.this[each.value.subnet_key].id
  tags          = merge(local.base_tags, { Name = each.value.name })

  lifecycle {
    precondition {
      condition     = var.subnets[each.value.subnet_key].tier == "public"
      error_message = "NAT gateway ${each.key} must sit in a public subnet; ${each.value.subnet_key} is private."
    }
  }

  # A public NAT gateway sends traffic out through the internet gateway, which must
  # exist before the gateway is usable; the provider documentation recommends it.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets
  provider = aws.project

  vpc_id = aws_vpc.this.id
  tags   = merge(local.base_tags, { Name = each.value.route_table_name })
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets
  provider = aws.project

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route" "private_nat" {
  for_each = local.nat_private_subnets
  provider = aws.project

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.nat_gateway_key].id
}

resource "aws_route" "private_transit" {
  for_each = local.transit_private_subnets
  provider = aws.project

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_cloudwatch_log_group" "flow_log" {
  provider = aws.project

  name              = var.flow_log.log_group_name
  retention_in_days = var.flow_log.retention_in_days
  kms_key_id        = var.flow_log.kms_key_arn
  tags              = merge(local.base_tags, { Name = var.flow_log.log_group_standard_name })
}

resource "aws_flow_log" "this" {
  provider = aws.project

  vpc_id                   = aws_vpc.this.id
  traffic_type             = var.flow_log.traffic_type
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_log.arn
  iam_role_arn             = var.flow_log.iam_role_arn
  max_aggregation_interval = var.flow_log.max_aggregation_interval
  tags                     = merge(local.base_tags, { Name = var.flow_log.name })
}
