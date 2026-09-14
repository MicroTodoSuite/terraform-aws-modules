# Name construction for the trail sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  trail_name  = "${local.governance_prefix}-ct-tfstate"
  bucket_name = "${local.governance_prefix}-s3-cloudtrail"

  # The trailing slash confines the trail to this bucket's objects.
  s3_object_arn_prefixes = ["arn:${data.aws_partition.current.partition}:s3:::${var.recorded_bucket_name}/"]

  log_retention = {
    current_days    = 365
    noncurrent_days = 30
  }
}
