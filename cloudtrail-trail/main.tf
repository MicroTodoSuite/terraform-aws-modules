# A CloudTrail trail and the private bucket that receives its logs. The trail records only the
# S3 object-level data events the root names, encrypts every log and digest file with the root's
# customer key, and validates each one. The bucket holds audit records, so it is protected from
# destruction (PC-IAC-010).
resource "aws_s3_bucket" "this" { # NOSONAR terraform:S6258 accepted in docs/iac-exceptions.md: access logs would need a further bucket, and a trail cannot record its own bucket
  provider = aws.project

  bucket        = local.bucket_full_name
  force_destroy = false
  tags          = local.bucket_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  provider = aws.project

  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# No S3 Bucket Key: with one, CloudTrail would also need kms:Decrypt on the key to create the
# trail, and the trail writes too few objects for the saved KMS requests to matter.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled       = false
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-trail-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention.current_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention.noncurrent_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Amazon S3 applies noncurrent-version rules only once versioning is on.
  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_policy" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id
  policy = local.bucket_policy

  # S3 rejects a bucket policy while the bucket's public access block is still
  # being written (OperationAborted); Terraform cannot see that ordering.
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_cloudtrail" "this" {
  provider = aws.project

  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.this.id
  kms_key_id                    = var.kms_key_arn
  enable_log_file_validation    = true
  enable_logging                = true
  include_global_service_events = false
  is_multi_region_trail         = false
  is_organization_trail         = false
  tags                          = local.trail_tags

  advanced_event_selector {
    name = "S3 object-level events under the recorded prefixes"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field       = "resources.ARN"
      starts_with = var.s3_object_arn_prefixes
    }
  }

  lifecycle {
    precondition {
      condition     = !anytrue([for arn in var.s3_object_arn_prefixes : startswith(arn, "${local.bucket_arn}/")])
      error_message = "The trail must not record data events on its own log bucket: it would record each of its own deliveries and deliver that record again."
    }
  }

  # CloudTrail refuses to create a trail whose bucket policy does not yet let it deliver.
  depends_on = [aws_s3_bucket_policy.this]
}
