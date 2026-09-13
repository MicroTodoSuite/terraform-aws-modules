# The EKS control plane with API-only access, encrypted secrets, and control-plane logs;
# its access entries and access policies; and its managed add-ons. Node groups come from
# the eks-node-group module. The role, keys, and subnets arrive as inputs (PC-IAC-023).
resource "aws_cloudwatch_log_group" "control_plane" {
  provider = aws.project

  name              = local.control_plane_log_group_name
  retention_in_days = var.control_plane_log_group.retention_in_days
  kms_key_id        = var.control_plane_log_group.kms_key_arn
  tags              = merge(local.base_tags, { Name = var.control_plane_log_group.standard_name })
}

resource "aws_eks_cluster" "this" {
  provider = aws.project

  name                          = var.cluster_name
  role_arn                      = var.cluster_role_arn
  version                       = var.kubernetes_version
  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons
  deletion_protection           = var.deletion_protection
  enabled_cluster_log_types     = var.enabled_log_types

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.endpoint_public_access_cidrs : null
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = var.secrets_kms_key_arn
    }
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  upgrade_policy {
    support_type = var.support_type
  }

  tags = merge(local.base_tags, { Name = var.cluster_name })

  # The log group must exist before the cluster starts logging, or Amazon EKS creates
  # its own without retention or encryption; no attribute of the cluster refers to it.
  depends_on = [aws_cloudwatch_log_group.control_plane]
}

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries
  provider = aws.project

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  type              = each.value.type
  kubernetes_groups = length(each.value.kubernetes_groups) > 0 ? each.value.kubernetes_groups : null
  tags              = local.base_tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.policy_associations
  provider = aws.project

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.this[each.value.entry_key].principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope_type
    namespaces = each.value.access_scope_type == "namespace" ? each.value.namespaces : null
  }
}

resource "aws_eks_addon" "before_compute" {
  for_each = local.addons_before_compute
  provider = aws.project

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  tags                        = local.base_tags
}

# Holds var.compute_ready so the add-ons below can wait for nodes. Passing a node group's
# ARN in is a value dependency, not a module-level depends_on, so no cycle forms with the
# eks-node-group module, which reads this module's cluster name.
resource "terraform_data" "compute_ready" {
  input = var.compute_ready
}

resource "aws_eks_addon" "after_compute" {
  for_each = local.addons_after_compute
  provider = aws.project

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  tags                        = local.base_tags

  # CoreDNS and the EBS CSI controller are Deployments: created before any node exists,
  # they report DEGRADED and the apply waits until it times out.
  depends_on = [aws_eks_addon.before_compute, terraform_data.compute_ready]
}
