# Name construction for the state-backend sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  bucket_name  = "${local.governance_prefix}-s3-tfstate"
  kms_key_name = "${local.governance_prefix}-kms-tfstate"
}
