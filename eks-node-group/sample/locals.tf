# Name construction for the eks-node-group sample: a small on-demand system group.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  cluster_name         = "${local.governance_prefix}-eks-sample"
  node_group_name      = "${local.governance_prefix}-ng-sample"
  launch_template_name = "${local.governance_prefix}-lt-sample"

  scaling     = { min_size = 1, desired_size = 1, max_size = 2 }
  root_volume = { size_gib = 50 }
  labels      = { "microtodosuite.io/capacity-owner" = "managed-node-group" }
}
