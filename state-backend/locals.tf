# Local values of the state-backend module: the bucket's full name and the tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  bucket_full_name = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}"

  bucket_tags = merge(local.governance_tags, var.additional_tags, { Name = var.bucket_name })
  key_tags    = merge(local.governance_tags, var.additional_tags, { Name = var.kms_key_name })
}
