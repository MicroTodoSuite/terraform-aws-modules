# The Terraform state backend: a private, versioned S3 bucket encrypted with its own rotating KMS key (PC-IAC-008).
# Both are protected from destruction (PC-IAC-010); a deliberate rebuild removes the protection in its own change.
resource "aws_kms_key" "this" {
  provider = aws.project

  description              = "Encrypts the Terraform state in ${local.bucket_full_name}"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = var.kms_deletion_window_in_days
  multi_region             = false
  tags                     = local.key_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  provider = aws.project

  name          = "alias/${var.kms_key_name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_s3_bucket" "this" { # NOSONAR terraform:S6258 accepted in docs/iac-exceptions.md: CloudTrail data events record access to this bucket (T043)
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

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_policy" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  # S3 rejects a bucket policy while the bucket's public access block is still
  # being written (OperationAborted); Terraform cannot see that ordering.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
