# Local values of the eks-cluster module: tags, the log group EKS writes to, the flattened
# policy associations, and the add-ons split by whether they need nodes.
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
  }

  base_tags = merge(local.governance_tags, var.additional_tags)

  # Amazon EKS writes control-plane logs to this group; creating it first sets its
  # retention and key instead of letting the service create one that never expires.
  control_plane_log_group_name = "/aws/eks/${var.cluster_name}/cluster"

  policy_associations = merge({}, [
    for entry_key, entry in var.access_entries : {
      for policy_key, policy in entry.policy_associations :
      "${entry_key}/${policy_key}" => merge(policy, { entry_key = entry_key })
    }
  ]...)

  addons_before_compute = { for name, addon in var.addons : name => addon if addon.before_compute }
  addons_after_compute  = { for name, addon in var.addons : name => addon if !addon.before_compute }
}
