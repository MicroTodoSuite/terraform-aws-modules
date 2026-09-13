# Name construction for the secret sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  secret_name = "${local.governance_prefix}-sm-sample"
}
