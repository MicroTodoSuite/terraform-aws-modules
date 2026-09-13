# Name construction for the iam-oidc-provider sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  standard_name = "${local.governance_prefix}-oidc-github"
}
