# Name construction for the Karpenter interruption sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  queue = {
    name                      = "${local.governance_prefix}-sqs-karpenter"
    message_retention_seconds = 300
    kms_key_arn               = ""
  }

  rule_names = {
    scheduled_change      = "${local.governance_prefix}-evr-karpscheduled"
    spot_interruption     = "${local.governance_prefix}-evr-karpspot"
    rebalance             = "${local.governance_prefix}-evr-karprebalance"
    instance_state_change = "${local.governance_prefix}-evr-karpstate"
    capacity_reservation  = "${local.governance_prefix}-evr-karpcapacity"
  }
}
