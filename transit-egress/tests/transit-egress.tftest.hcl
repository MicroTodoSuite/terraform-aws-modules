# Plan-time tests of the transit-egress module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_resource "aws_ec2_transit_gateway" {
    defaults = { id = "tgw-0123456789abcdef0", arn = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0" }
  }
  mock_resource "aws_ec2_transit_gateway_vpc_attachment" {
    defaults = { id = "tgw-attach-0123456789abcdef0" }
  }
  mock_resource "aws_ec2_transit_gateway_route_table" {
    defaults = { id = "tgw-rtb-0123456789abcdef0" }
  }
}

variables {
  client               = "lex"
  project              = "mts"
  environment          = "shd"
  transit_gateway_name = "lex-mts-shd-tgw-egress"
  hub_attachment_name  = "lex-mts-shd-tgwa-egress"
  hub_route_table_name = "lex-mts-shd-rtb-tgwhub"
  hub_vpc = {
    id                    = "vpc-0123456789abcdef0"
    cidr_block            = "10.50.0.0/16"
    attachment_subnet_ids = ["subnet-0123456789abcdef0"]
    public_route_table_id = "rtb-0123456789abcdef0"
  }
  spokes = {
    fdev = { vpc_cidr = "10.30.0.0/16", route_table_name = "lex-mts-shd-rtb-tgwfdev" }
    fstg = { vpc_cidr = "10.31.0.0/16", route_table_name = "lex-mts-shd-rtb-tgwfstg" }
  }
}

run "creates_a_transit_gateway_that_isolates_its_attachments" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.default_route_table_association == "disable" && aws_ec2_transit_gateway.this.default_route_table_propagation == "disable"
    error_message = "No attachment may join a shared table or advertise its CIDR by default."
  }

  assert {
    condition     = aws_ec2_transit_gateway.this.auto_accept_shared_attachments == "disable" && aws_ec2_transit_gateway.this.tags["Name"] == "lex-mts-shd-tgw-egress"
    error_message = "Shared attachments must need acceptance, and the gateway must carry its standard name."
  }
}

run "attaches_the_egress_vpc_to_its_own_route_table" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = !aws_ec2_transit_gateway_vpc_attachment.hub.transit_gateway_default_route_table_association && !aws_ec2_transit_gateway_vpc_attachment.hub.transit_gateway_default_route_table_propagation
    error_message = "The hub attachment must stay out of the default tables."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.hub.vpc_id == "vpc-0123456789abcdef0" && aws_ec2_transit_gateway_vpc_attachment.hub.subnet_ids == toset(["subnet-0123456789abcdef0"])
    error_message = "The hub attachment must sit in the egress VPC's private subnets."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route_table_association.hub.transit_gateway_attachment_id == aws_ec2_transit_gateway_vpc_attachment.hub.id && aws_ec2_transit_gateway_route_table_association.hub.transit_gateway_route_table_id == aws_ec2_transit_gateway_route_table.hub.id
    error_message = "The hub attachment must be associated with the hub route table."
  }
}

run "gives_each_spoke_an_empty_table_and_a_return_route" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = keys(aws_ec2_transit_gateway_route_table.spoke) == ["fdev", "fstg"] && aws_ec2_transit_gateway_route_table.spoke["fdev"].tags["Spoke"] == "fdev"
    error_message = "Each spoke must get its own route table."
  }

  assert {
    condition     = aws_route.spoke_return["fdev"].destination_cidr_block == "10.30.0.0/16" && aws_route.spoke_return["fdev"].route_table_id == "rtb-0123456789abcdef0" && aws_route.spoke_return["fdev"].transit_gateway_id == aws_ec2_transit_gateway.this.id
    error_message = "The NAT gateway's subnet must route each spoke's replies back through the transit gateway."
  }
}

run "a_hub_without_spokes_has_no_spoke_tables_or_routes" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    spokes = {}
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route_table.spoke) == 0 && length(aws_route.spoke_return) == 0
    error_message = "A hub with no spokes must create no spoke table and no return route."
  }
}

run "rejects_overlapping_spokes" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    spokes = {
      fdev = { vpc_cidr = "10.30.0.0/16", route_table_name = "lex-mts-shd-rtb-tgwfdev" }
      fstg = { vpc_cidr = "10.30.128.0/17", route_table_name = "lex-mts-shd-rtb-tgwfstg" }
    }
  }

  expect_failures = [var.spokes]
}

run "rejects_a_spoke_that_overlaps_the_egress_vpc" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    spokes = {
      fdev = { vpc_cidr = "10.50.0.0/20", route_table_name = "lex-mts-shd-rtb-tgwfdev" }
    }
  }

  expect_failures = [var.spokes]
}

run "rejects_a_hub_attachment_without_subnets" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    hub_vpc = {
      id                    = "vpc-0123456789abcdef0"
      cidr_block            = "10.50.0.0/16"
      attachment_subnet_ids = []
      public_route_table_id = "rtb-0123456789abcdef0"
    }
  }

  expect_failures = [var.hub_vpc]
}
