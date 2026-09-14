# Local values of the CloudTrail trail module: the bucket's full name, the trail's ARN, the
# bucket policy, and the tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  bucket_full_name = "${var.bucket_name}-${local.account_id}"
  bucket_arn       = "arn:${local.partition}:s3:::${local.bucket_full_name}"

  # CloudTrail checks the bucket policy when the trail is created, so the policy must name the
  # trail before the trail exists; its ARN is built rather than read.
  trail_arn = "arn:${local.partition}:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${var.trail_name}"

  cloudtrail_principal = "cloudtrail.${data.aws_partition.current.dns_suffix}"

  # The CloudTrail User Guide's bucket policy, confined to this trail by aws:SourceArn, plus
  # the transport denial every bucket of the project carries.
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = local.cloudtrail_principal }
        Action    = "s3:GetBucketAcl"
        Resource  = local.bucket_arn
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "AllowCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = local.cloudtrail_principal }
        Action    = "s3:PutObject"
        Resource  = "${local.bucket_arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  bucket_tags = merge(local.governance_tags, var.additional_tags, { Name = var.bucket_name })
  trail_tags  = merge(local.governance_tags, var.additional_tags, { Name = var.trail_name })
}
