# Local values of the eks-node-group module: the tags of the node group, its launch template,
# and everything the template launches.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  base_tags = merge(local.governance_tags, var.additional_tags)

  node_tags = merge(local.base_tags, { Name = var.node_group_name })
}
