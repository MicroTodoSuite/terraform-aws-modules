# Plan-time tests of the route53-zone module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client        = "lex"
  project       = "mts"
  environment   = "shd"
  zone_name     = "microtodosuite.abrdns.com"
  standard_name = "lex-mts-shd-dns-public"
}

run "creates_a_protected_public_zone" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_route53_zone.this.name == "microtodosuite.abrdns.com"
    error_message = "The zone's name must be the domain."
  }

  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "Destroying the zone must never delete records managed elsewhere."
  }

  assert {
    condition     = aws_route53_zone.this.tags["Name"] == "lex-mts-shd-dns-public"
    error_message = "The Name tag must follow the standard pattern (MTS-IAC-101)."
  }

  assert {
    condition     = length(aws_route53_zone.this.vpc) == 0
    error_message = "The zone must be public: no VPC association."
  }
}

run "rejects_a_zone_name_that_is_not_a_domain" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    zone_name = "Not_A_Domain"
  }

  expect_failures = [var.zone_name]
}

run "rejects_a_standard_name_longer_than_28_characters" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    standard_name = "lex-mts-shd-dns-publiczonelong"
  }

  expect_failures = [var.standard_name]
}
