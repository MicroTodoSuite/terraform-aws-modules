# Name construction for the route53-zone sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  zone_name     = "sample.microtodosuite.example"
  standard_name = "${local.governance_prefix}-dns-sample"
}
