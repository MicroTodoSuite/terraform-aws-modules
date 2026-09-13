# Local values of the security-group module: the group's tags and its rules' tags.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  group_tags = merge(local.governance_tags, var.additional_tags, { Name = var.security_group_name })
  rule_tags  = merge(local.governance_tags, var.additional_tags)
}
