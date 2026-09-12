# Plan-time tests of the state-backend module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
      key_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::lex-mts-shd-s3-tfstate-123456789012"
      id  = "lex-mts-shd-s3-tfstate-123456789012"
    }
  }
}

variables {
  client       = "lex"
  project      = "mts"
  environment  = "shd"
  bucket_name  = "lex-mts-shd-s3-tfstate"
  kms_key_name = "lex-mts-shd-kms-tfstate"
}

run "creates_a_private_versioned_bucket_named_for_the_account" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "lex-mts-shd-s3-tfstate-123456789012"
    error_message = "The bucket name must carry the account ID suffix (PC-IAC-008)."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Name"] == "lex-mts-shd-s3-tfstate"
    error_message = "The Name tag must be the standard name without the account suffix (MTS-IAC-101)."
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "The state bucket must never be emptied by a destroy."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "State must be versioned so that a bad write can be rolled back."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled; the bucket owner owns every object."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "Every public access setting must be blocked."
  }
}

run "encrypts_with_its_own_rotating_key_and_requires_tls" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation && aws_kms_key.this.deletion_window_in_days == 30
    error_message = "The key must rotate and keep the longest deletion window by default."
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/lex-mts-shd-kms-tfstate"
    error_message = "The alias must be alias/ followed by the standard key name (MTS-IAC-101)."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == aws_kms_key.this.arn
    error_message = "The bucket must encrypt with the module's own key."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled
    error_message = "S3 Bucket Keys must be enabled to limit KMS requests."
  }

  assert {
    condition     = contains(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).blocked_encryption_types, "SSE-C")
    error_message = "Uploads with customer-provided keys must be blocked."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The bucket policy must deny requests that do not use TLS."
  }
}

run "rejects_an_invalid_bucket_name" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    bucket_name = "Invalid_Name"
  }

  expect_failures = [var.bucket_name]
}

run "rejects_a_deletion_window_outside_the_kms_limits" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    kms_deletion_window_in_days = 3
  }

  expect_failures = [var.kms_deletion_window_in_days]
}
