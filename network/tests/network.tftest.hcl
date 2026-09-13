# Plan-time tests of the network module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_resource "aws_internet_gateway" {
    defaults = { id = "igw-0123456789abcdef0" }
  }
  mock_resource "aws_subnet" {
    defaults = { id = "subnet-0123456789abcdef0" }
  }
  mock_resource "aws_route_table" {
    defaults = { id = "rtb-0123456789abcdef0" }
  }
  mock_resource "aws_eip" {
    defaults = { id = "eipalloc-0123456789abcdef0", allocation_id = "eipalloc-0123456789abcdef0" }
  }
  mock_resource "aws_nat_gateway" {
    defaults = { id = "nat-0123456789abcdef0" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vpc-flow-logs/lex-mts-eco-vpc-main" }
  }
}

variables {
  client                  = "lex"
  project                 = "mts"
  environment             = "eco"
  vpc                     = { name = "lex-mts-eco-vpc-main", cidr_block = "10.10.0.0/16" }
  internet_gateway_name   = "lex-mts-eco-igw-main"
  public_route_table_name = "lex-mts-eco-rtb-public"
  transit_gateway_id      = ""
  subnets = {
    puba  = { name = "lex-mts-eco-sub-puba", availability_zone = "us-east-1a", cidr_block = "10.10.0.0/24", tier = "public", tags = { "kubernetes.io/role/elb" = "1" } }
    pubb  = { name = "lex-mts-eco-sub-pubb", availability_zone = "us-east-1b", cidr_block = "10.10.1.0/24", tier = "public" }
    priva = { name = "lex-mts-eco-sub-priva", availability_zone = "us-east-1a", cidr_block = "10.10.16.0/20", tier = "private", route_table_name = "lex-mts-eco-rtb-priva", egress = "nat", nat_gateway_key = "a" }
    privb = { name = "lex-mts-eco-sub-privb", availability_zone = "us-east-1b", cidr_block = "10.10.32.0/20", tier = "private", route_table_name = "lex-mts-eco-rtb-privb", egress = "nat", nat_gateway_key = "b" }
  }
  nat_gateways = {
    a = { name = "lex-mts-eco-nat-a", eip_name = "lex-mts-eco-eip-a", subnet_key = "puba" }
    b = { name = "lex-mts-eco-nat-b", eip_name = "lex-mts-eco-eip-b", subnet_key = "pubb" }
  }
  flow_log = {
    name                    = "lex-mts-eco-fl-main"
    log_group_name          = "/aws/vpc-flow-logs/lex-mts-eco-vpc-main"
    log_group_standard_name = "lex-mts-eco-cwl-flowlogs"
    retention_in_days       = 90
    kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    iam_role_arn            = "arn:aws:iam::123456789012:role/lex-mts-shd-role-flowlogs"
  }
}

run "zonal_nat_gateways_route_each_private_subnet" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.10.0.0/16" && aws_vpc.this.enable_dns_hostnames && aws_vpc.this.enable_dns_support && aws_vpc.this.tags["Name"] == "lex-mts-eco-vpc-main"
    error_message = "The VPC must have the given block, DNS support and hostnames, and its standard name."
  }

  assert {
    condition     = length(aws_subnet.this) == 4 && alltrue([for subnet in aws_subnet.this : subnet.map_public_ip_on_launch == false])
    error_message = "Every subnet is created, and none assigns public addresses on launch."
  }

  assert {
    condition     = aws_subnet.this["puba"].tags["kubernetes.io/role/elb"] == "1" && aws_subnet.this["puba"].tags["Name"] == "lex-mts-eco-sub-puba"
    error_message = "Discovery tags and the standard name must reach the subnet."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2 && length(aws_eip.this) == 2 && length(aws_route.private_nat) == 2 && length(aws_route.private_transit) == 0
    error_message = "Each zonal NAT gateway needs its Elastic IP, and each private subnet one default route through NAT."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 2 && length(aws_route_table_association.private) == 2 && aws_route.public_internet.gateway_id == "igw-0123456789abcdef0"
    error_message = "Public subnets share the public route table through the internet gateway; private subnets get their own."
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL" && aws_flow_log.this.max_aggregation_interval == 60 && aws_flow_log.this.log_destination == "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vpc-flow-logs/lex-mts-eco-vpc-main"
    error_message = "Flow logs must capture all traffic every minute into the module's log group."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_log.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000" && aws_cloudwatch_log_group.flow_log.retention_in_days == 90
    error_message = "The flow-log group must be encrypted with the given key and keep the given retention."
  }
}

run "a_single_nat_gateway_serves_every_private_subnet" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    subnets = {
      puba  = { name = "lex-mts-eco-sub-puba", availability_zone = "us-east-1a", cidr_block = "10.10.0.0/24", tier = "public" }
      priva = { name = "lex-mts-eco-sub-priva", availability_zone = "us-east-1a", cidr_block = "10.10.16.0/20", tier = "private", route_table_name = "lex-mts-eco-rtb-priva", egress = "nat", nat_gateway_key = "a" }
      privb = { name = "lex-mts-eco-sub-privb", availability_zone = "us-east-1b", cidr_block = "10.10.32.0/20", tier = "private", route_table_name = "lex-mts-eco-rtb-privb", egress = "nat", nat_gateway_key = "a" }
    }
    nat_gateways = {
      a = { name = "lex-mts-eco-nat-a", eip_name = "lex-mts-eco-eip-a", subnet_key = "puba" }
    }
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "One NAT gateway must carry both private subnets' default routes."
  }
}

run "a_transit_spoke_has_no_nat_gateway" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    subnets = {
      puba  = { name = "lex-mts-fstg-sub-puba", availability_zone = "us-east-1a", cidr_block = "10.20.0.0/24", tier = "public" }
      priva = { name = "lex-mts-fstg-sub-priva", availability_zone = "us-east-1a", cidr_block = "10.20.16.0/20", tier = "private", route_table_name = "lex-mts-fstg-rtb-priva", egress = "transit" }
    }
    nat_gateways = {}
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_eip.this) == 0 && length(aws_route.private_transit) == 1 && aws_route.private_transit["priva"].transit_gateway_id == "tgw-0123456789abcdef0"
    error_message = "A transit spoke routes private traffic through the transit gateway and owns no NAT gateway or Elastic IP."
  }
}

run "rejects_nat_egress_without_a_nat_gateway" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    nat_gateways = {}
  }

  expect_failures = [var.subnets]
}

run "rejects_a_nat_gateway_in_a_private_subnet" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    nat_gateways = {
      a = { name = "lex-mts-eco-nat-a", eip_name = "lex-mts-eco-eip-a", subnet_key = "priva" }
      b = { name = "lex-mts-eco-nat-b", eip_name = "lex-mts-eco-eip-b", subnet_key = "pubb" }
    }
  }

  expect_failures = [aws_nat_gateway.this]
}

run "rejects_transit_egress_without_a_transit_gateway" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    subnets = {
      puba  = { name = "lex-mts-fstg-sub-puba", availability_zone = "us-east-1a", cidr_block = "10.20.0.0/24", tier = "public" }
      priva = { name = "lex-mts-fstg-sub-priva", availability_zone = "us-east-1a", cidr_block = "10.20.16.0/20", tier = "private", route_table_name = "lex-mts-fstg-rtb-priva", egress = "transit" }
    }
    nat_gateways = {}
  }

  expect_failures = [var.subnets]
}

run "rejects_a_flow_log_that_never_expires" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    flow_log = {
      name                    = "lex-mts-eco-fl-main"
      log_group_name          = "/aws/vpc-flow-logs/lex-mts-eco-vpc-main"
      log_group_standard_name = "lex-mts-eco-cwl-flowlogs"
      retention_in_days       = 0
      kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
      iam_role_arn            = "arn:aws:iam::123456789012:role/lex-mts-shd-role-flowlogs"
    }
  }

  expect_failures = [var.flow_log]
}
