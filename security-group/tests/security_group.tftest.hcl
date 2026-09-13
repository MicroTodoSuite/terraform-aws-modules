# Plan-time tests of the security-group module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-0123456789abcdef0"
    }
  }
}

variables {
  client              = "lex"
  project             = "mts"
  environment         = "eco"
  security_group_name = "lex-mts-eco-sg-nodes"
  description         = "Worker nodes of the economical cluster."
  vpc_id              = "vpc-0123456789abcdef0"
  ingress_rules = {
    https = { description = "HTTPS from the VPC", ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "10.10.0.0/16" }
    peers = { description = "Node-to-node traffic", ip_protocol = "-1", self = true }
  }
  egress_rules = {
    vpc = { description = "Anything inside the VPC", ip_protocol = "-1", cidr_ipv4 = "10.10.0.0/16" }
  }
}

run "creates_the_group_with_separate_rules" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_security_group.this.name == "lex-mts-eco-sg-nodes" && aws_security_group.this.vpc_id == "vpc-0123456789abcdef0" && aws_security_group.this.tags["Name"] == "lex-mts-eco-sg-nodes"
    error_message = "The group must carry the built name, in the given VPC, with a matching Name tag."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 2 && length(aws_vpc_security_group_egress_rule.this) == 1
    error_message = "Each rule entry must become one rule resource."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["peers"].referenced_security_group_id == "sg-0123456789abcdef0" && aws_vpc_security_group_ingress_rule.this["peers"].from_port == null
    error_message = "A self rule must reference the group itself, and an all-protocol rule takes no ports."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["https"].cidr_ipv4 == "10.10.0.0/16" && aws_vpc_security_group_ingress_rule.this["https"].from_port == 443
    error_message = "A CIDR rule must keep its source and ports."
  }
}

run "rejects_a_rule_with_two_sources" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    ingress_rules = {
      both = { description = "Ambiguous", ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "10.10.0.0/16", self = true }
    }
  }

  expect_failures = [var.ingress_rules]
}

run "rejects_a_port_rule_without_ports" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    egress_rules = {
      https = { description = "HTTPS out", ip_protocol = "tcp", cidr_ipv4 = "10.10.0.0/16" }
    }
  }

  expect_failures = [var.egress_rules]
}

run "rejects_an_invalid_vpc_id" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    vpc_id = "not-a-vpc"
  }

  expect_failures = [var.vpc_id]
}
