# Plan-time tests of the kms-key module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "shd"
  key_name    = "lex-mts-shd-kms-flowlogs"
  description = "Encrypts the VPC flow-log groups of every environment."
}

run "creates_a_rotating_symmetric_key_with_its_alias" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation && aws_kms_key.this.deletion_window_in_days == 30
    error_message = "The key must rotate and keep the longest deletion window by default."
  }

  assert {
    condition     = aws_kms_key.this.key_usage == "ENCRYPT_DECRYPT" && aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT" && !aws_kms_key.this.multi_region
    error_message = "The key must be a regional symmetric encryption key."
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/lex-mts-shd-kms-flowlogs" && aws_kms_key.this.tags["Name"] == "lex-mts-shd-kms-flowlogs"
    error_message = "The alias must be alias/ followed by the standard name, which is also the Name tag."
  }
}

run "applies_a_given_key_policy" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Sid = "AccountAdministration", Effect = "Allow", Principal = { AWS = "arn:aws:iam::123456789012:root" }, Action = "kms:*", Resource = "*" }]
    })
  }

  assert {
    condition     = jsondecode(aws_kms_key.this.policy).Statement[0].Sid == "AccountAdministration"
    error_message = "A given policy must become the key policy."
  }
}

run "rejects_a_policy_that_is_not_json" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    policy = "not json"
  }

  expect_failures = [var.policy]
}

run "rejects_a_deletion_window_outside_the_kms_limits" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    deletion_window_in_days = 3
  }

  expect_failures = [var.deletion_window_in_days]
}
