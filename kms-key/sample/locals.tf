# Name construction for the kms-key sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  key_name = "${local.governance_prefix}-kms-sample"
}
