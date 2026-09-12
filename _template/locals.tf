# Local values: governance tags merged with the name the root built (PC-IAC-004, PC-IAC-012).
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  tags = merge(local.governance_tags, { Name = var.queue.name }, var.additional_tags)
}
