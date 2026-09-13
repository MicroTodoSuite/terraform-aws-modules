# eks-cluster

One Amazon EKS control plane. It includes its control-plane log group, its
access entries and access policies, and its managed add-ons. It replaces the
cluster half of the upstream `terraform-aws-modules/eks` that
`microservice-app-ops` used. That module creates the cluster role, the
secrets key, and the security groups itself, which PC-IAC-023 forbids. Here
they arrive as inputs:

- the cluster role comes from `iam-role`;
- the secrets and log keys come from `kms-key`;
- the subnets come from `network`;
- any extra security groups come from `security-group`.

Node groups are the `eks-node-group` module.

## Defaults

| Setting | Default | Why |
| --- | --- | --- |
| Authentication | `API` access entries only; the creator gets no implicit access | Every administrator is named in `access_entries` |
| Endpoint | Private only | A public endpoint needs `endpoint_public_access_cidrs`, never `/0` |
| Secrets | Encrypted with `secrets_kms_key_arn` | Required input |
| Control-plane logs | All five types to `/aws/eks/<name>/cluster`, created first with a finite retention and a KMS key | Otherwise EKS creates the group with no expiry |
| Deletion protection | On | Turn it off in a reviewed change before a teardown |
| Upgrade policy | `STANDARD` | No extended-support charges |
| Self-managed add-ons | Not bootstrapped | The add-ons are managed, from `addons`; changing this replaces the cluster |

## Add-ons and compute

Add-ons marked `before_compute = true` install with the cluster; they are
DaemonSets, such as `vpc-cni` and `kube-proxy`. The rest are Deployments,
such as `coredns` and `aws-ebs-csi-driver`. They wait for `compute_ready`,
because without nodes they stay `DEGRADED` and the apply times out.

Pass the node group's ARN into `compute_ready`. That is a value dependency,
so no cycle forms with `eks-node-group`, which reads `cluster_name` from
this module:

```hcl
module "eks_cluster" {
  # ...
  addons = {
    vpc-cni    = { addon_version = "v1.23.0-eksbuild.1", before_compute = true, service_account_role_arn = module.vpc_cni_role.role_arn }
    kube-proxy = { addon_version = "v1.35.3-eksbuild.18", before_compute = true }
    coredns    = { addon_version = "v1.14.3-eksbuild.3" }
  }
  compute_ready = [module.system_node_group.node_group_arn]
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `cluster_name` | `string` | — | Standard name, at most 28 characters |
| `kubernetes_version` | `string` | — | Minor version in standard support, such as `1.35` |
| `support_type` | `string` | `STANDARD` | `STANDARD` or `EXTENDED` |
| `cluster_role_arn` | `string` | — | Control-plane role, with `AmazonEKSClusterPolicy` attached |
| `subnet_ids` | `list(string)` | — | Private subnets in at least two zones |
| `security_group_ids` | `list(string)` | — | Extra control-plane security groups; `[]` for none |
| `endpoint_public_access` | `bool` | `false` | Adds a public endpoint |
| `endpoint_public_access_cidrs` | `list(string)` | — | Required with a public endpoint, `[]` without; never `/0` |
| `service_ipv4_cidr` | `string` | — | Service CIDR, `/24`–`/12`, fixed at creation, outside the VPC |
| `secrets_kms_key_arn` | `string` | — | Key for Kubernetes secrets |
| `enabled_log_types` | `list(string)` | all five | Control-plane log types |
| `control_plane_log_group` | `object` | — | `standard_name`, `retention_in_days`, `kms_key_arn`; the key policy must allow CloudWatch Logs |
| `deletion_protection` | `bool` | `true` | Refuse deletion |
| `bootstrap_self_managed_addons` | `bool` | `false` | Install self-managed add-ons at creation |
| `access_entries` | `map(object)` | `{}` | `principal_arn`, `type`, `kubernetes_groups`, `policy_associations` (`policy_arn`, `access_scope_type`, `namespaces`) |
| `addons` | `map(object)` | `{}` | Keyed by add-on name: `addon_version`, `before_compute`, `service_account_role_arn`, `configuration_values`, `resolve_conflicts_on_update` |
| `compute_ready` | `list(string)` | `[]` | Values that exist once nodes do |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

- `cluster_name`, `cluster_arn`, `cluster_endpoint`, `cluster_certificate_authority_data`
- `cluster_version`, `cluster_platform_version`
- `oidc_issuer_url` (for `iam-oidc-provider`)
- `cluster_security_group_id`
- `control_plane_log_group_name`, `control_plane_log_group_arn`
- `access_entry_arns`, `addon_arns`

## Example

```hcl
module "eks_cluster" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//eks-cluster?ref=eks-cluster-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client              = var.client
  project             = var.project
  environment         = var.environment
  cluster_name        = "${local.governance_prefix}-eks-main"
  kubernetes_version  = var.kubernetes_version
  cluster_role_arn    = module.cluster_role.role_arn
  subnet_ids          = values(module.network.private_subnet_ids)
  security_group_ids  = []
  service_ipv4_cidr   = "172.20.0.0/16"
  secrets_kms_key_arn = module.eks_secrets_key.key_arn

  endpoint_public_access_cidrs = []

  control_plane_log_group = {
    standard_name     = "${local.governance_prefix}-cwl-eks"
    retention_in_days = 90
    kms_key_arn       = module.log_key.key_arn
  }

  access_entries = {
    admin = {
      principal_arn       = var.cluster_admin_role_arn
      policy_associations = { cluster_admin = { policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" } }
    }
  }
}
```
