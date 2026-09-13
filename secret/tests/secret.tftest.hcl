# Plan-time tests of the secret module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "eco"
  secret_name = "lex-mts-eco-sm-jwtdev"
  description = "JWT signing key of the dev namespace."
  kms_key_arn = ""
}

run "creates_the_container_without_a_value" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_secretsmanager_secret.this.name == "lex-mts-eco-sm-jwtdev" && aws_secretsmanager_secret.this.tags["Name"] == "lex-mts-eco-sm-jwtdev"
    error_message = "The secret must carry the name the root built, also as its Name tag."
  }

  assert {
    condition     = aws_secretsmanager_secret.this.recovery_window_in_days == 30 && aws_secretsmanager_secret.this.kms_key_id == null
    error_message = "A deleted secret stays recoverable for 30 days, and an empty key means the account's key."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 0
    error_message = "Version 0 must write no value."
  }
}

run "writes_the_value_write_only_when_versioned" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    secret_value         = "a-value-that-never-reaches-state"
    secret_value_version = 1
    kms_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 1 && aws_secretsmanager_secret_version.this[0].secret_string_wo_version == 1
    error_message = "A positive version must write the value once, through the write-only argument."
  }

  assert {
    condition     = aws_secretsmanager_secret.this.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    error_message = "A given key must encrypt the secret."
  }
}

run "rejects_a_recovery_window_outside_the_limits" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    recovery_window_in_days = 0
  }

  expect_failures = [var.recovery_window_in_days]
}

run "rejects_an_empty_value" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    secret_value         = ""
    secret_value_version = 1
  }

  expect_failures = [var.secret_value]
}
