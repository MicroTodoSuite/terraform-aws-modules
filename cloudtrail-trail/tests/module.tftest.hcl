# Plan-time tests of the CloudTrail trail module against a mocked AWS provider (PC-IAC-018).
# The bucket policy and the event selector follow the CloudTrail User Guide.
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }

  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }

  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::lex-mts-shd-s3-cloudtrail-123456789012"
      id  = "lex-mts-shd-s3-cloudtrail-123456789012"
    }
  }

  mock_resource "aws_cloudtrail" {
    defaults = { arn = "arn:aws:cloudtrail:us-east-1:123456789012:trail/lex-mts-shd-ct-tfstate" }
  }
}

variables {
  client                 = "lex"
  project                = "mts"
  environment            = "shd"
  trail_name             = "lex-mts-shd-ct-tfstate"
  bucket_name            = "lex-mts-shd-s3-cloudtrail"
  kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  s3_object_arn_prefixes = ["arn:aws:s3:::lex-mts-shd-s3-tfstate-123456789012/"]
  log_retention          = { current_days = 365, noncurrent_days = 30 }
}

run "names_the_trail_and_its_bucket_for_the_account" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_cloudtrail.this.name == "lex-mts-shd-ct-tfstate" && aws_cloudtrail.this.tags["Name"] == "lex-mts-shd-ct-tfstate"
    error_message = "The trail must carry the standard name the root built (MTS-IAC-101)."
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "lex-mts-shd-s3-cloudtrail-123456789012" && aws_s3_bucket.this.tags["Name"] == "lex-mts-shd-s3-cloudtrail"
    error_message = "The bucket name must carry the account ID suffix, and its Name tag the standard name without it."
  }

  assert {
    condition     = aws_cloudtrail.this.s3_bucket_name == "lex-mts-shd-s3-cloudtrail-123456789012"
    error_message = "The trail must deliver to its own bucket."
  }
}

run "keeps_the_log_bucket_private_versioned_and_undeletable" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false && one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "Audit records must be versioned and never emptied by a destroy."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled; the bucket owner owns every log file."
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

run "encrypts_and_validates_every_log_file" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_cloudtrail.this.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000" && aws_cloudtrail.this.enable_log_file_validation
    error_message = "The trail must encrypt with the root's customer key and write digest files, so a changed or deleted log file is detectable."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms" && one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    error_message = "The bucket must encrypt by default with the same customer key."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled == false && contains(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).blocked_encryption_types, "SSE-C")
    error_message = "Without an S3 Bucket Key the key policy needs no decrypt grant to CloudTrail; uploads with customer-provided keys must be blocked."
  }
}

run "records_only_object_events_of_the_named_buckets" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = length(aws_cloudtrail.this.advanced_event_selector) == 1 && length(aws_cloudtrail.this.event_selector) == 0
    error_message = "The trail must record through exactly one advanced event selector."
  }

  assert {
    condition     = { for selector in one(aws_cloudtrail.this.advanced_event_selector).field_selector : selector.field => selector.equals if selector.field != "resources.ARN" } == { eventCategory = ["Data"], "resources.type" = ["AWS::S3::Object"] }
    error_message = "The selector must record S3 object-level data events and nothing else."
  }

  assert {
    condition     = one([for selector in one(aws_cloudtrail.this.advanced_event_selector).field_selector : selector.starts_with if selector.field == "resources.ARN"]) == ["arn:aws:s3:::lex-mts-shd-s3-tfstate-123456789012/"]
    error_message = "The selector must be confined to the object ARN prefixes the root named."
  }

  assert {
    condition     = !aws_cloudtrail.this.include_global_service_events && !aws_cloudtrail.this.is_multi_region_trail && !aws_cloudtrail.this.is_organization_trail
    error_message = "A trail that records one Region's bucket needs neither global service events nor every Region."
  }
}

run "lets_only_this_trail_deliver_and_only_over_tls" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Action == "s3:GetBucketAcl" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Resource == "arn:aws:s3:::lex-mts-shd-s3-cloudtrail-123456789012" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Condition.StringEquals == { "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:123456789012:trail/lex-mts-shd-ct-tfstate" }
    error_message = "Only this trail may read the bucket ACL."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[1].Action == "s3:PutObject" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[1].Resource == "arn:aws:s3:::lex-mts-shd-s3-cloudtrail-123456789012/AWSLogs/123456789012/*" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[1].Condition.StringEquals == { "s3:x-amz-acl" = "bucket-owner-full-control", "aws:SourceArn" = "arn:aws:cloudtrail:us-east-1:123456789012:trail/lex-mts-shd-ct-tfstate" }
    error_message = "Only this trail may write, only under its account's AWSLogs prefix, and only handing the bucket owner full control."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Principal.Service == "cloudtrail.amazonaws.com" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[2].Effect == "Deny" && jsondecode(aws_s3_bucket_policy.this.policy).Statement[2].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "The grants must name the CloudTrail service, and every request made without TLS must be denied."
  }
}

run "expires_logs_after_their_retention" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this.rule).expiration).days == 365 && one(one(aws_s3_bucket_lifecycle_configuration.this.rule).noncurrent_version_expiration).noncurrent_days == 30
    error_message = "Log files must expire after the retention the root chose, and their old versions after the noncurrent retention."
  }

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this.rule).abort_incomplete_multipart_upload).days_after_initiation == 7
    error_message = "Incomplete uploads must not accumulate."
  }
}

run "refuses_to_record_its_own_log_bucket" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    s3_object_arn_prefixes = ["arn:aws:s3:::lex-mts-shd-s3-cloudtrail-123456789012/"]
  }

  expect_failures = [aws_cloudtrail.this]
}

run "rejects_an_object_prefix_without_its_slash" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    s3_object_arn_prefixes = ["arn:aws:s3:::lex-mts-shd-s3-tfstate-123456789012"]
  }

  expect_failures = [var.s3_object_arn_prefixes]
}

run "rejects_a_trail_name_cloudtrail_would_refuse" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    trail_name = "lex-mts--shd-ct-tfstate"
  }

  expect_failures = [var.trail_name]
}

run "rejects_a_key_that_is_not_a_kms_key_arn" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    kms_key_arn = "alias/lex-mts-shd-kms-cloudtrail"
  }

  expect_failures = [var.kms_key_arn]
}
