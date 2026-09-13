# Name construction for the ecr-repository sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  repositories = {
    authapi = { name = "${local.governance_prefix}-ecr-authapi" }
  }
}
