# eks-node-group

One Amazon EKS managed node group and the launch template it launches from.
It replaces the upstream `eks-managed-node-group` submodule that
`microservice-app-ops` used for its bootstrap group. The node role, the
subnets, and any security groups arrive as inputs (PC-IAC-023). Amazon EKS
creates the node role's access entry itself, so `eks-cluster` needs none for
it.

## Defaults

| Setting | Value | Why |
| --- | --- | --- |
| Instance metadata | IMDSv2 required, hop limit 1, instance tags not exposed | Pods get AWS credentials through their service accounts and cannot reach the node's metadata service; set `metadata_hop_limit = 2` only for containers that need it |
| Root volume | Encrypted gp3, size from `root_volume` | With a launch template the disk size must be set there, not on the node group |
| Security groups | None in the template, so Amazon EKS applies the cluster security group | Any group set in the template replaces the cluster group; include rules that reach the control plane |
| Versions | `kubernetes_version` and `release_version` explicit | Nodes roll only in a reviewed change |
| Replacement | Physical name is the standard name plus a unique suffix, with create-before-destroy | A replaced group comes up beside the old one |
| Node repair | On | Amazon EKS replaces unhealthy nodes |

The launch template sets nothing Amazon EKS forbids there: no subnet, no
instance profile, and no shutdown behavior. Instance types stay on the node
group.

## Ordering

`iam-role`'s `role_arn` output does not wait for the role's policy
attachments. Give the module call `depends_on = [module.node_role]`, so the
nodes start with their policies in place and the group is deleted before them.
Then feed `node_group_arn` into `eks-cluster`'s `compute_ready`, so CoreDNS
and the other add-ons that need nodes wait for this group.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `cluster_name` | `string` | — | From `eks-cluster` |
| `node_group_name`, `launch_template_name` | `string` | — | Standard names |
| `node_role_arn` | `string` | — | Node role with the worker node and registry pull policies |
| `subnet_ids` | `list(string)` | — | Private subnets |
| `security_group_ids` | `list(string)` | — | `[]` for the cluster security group |
| `kubernetes_version`, `release_version` | `string` | — | Pinned versions |
| `ami_type` | `string` | — | Amazon Linux 2023 or Bottlerocket type |
| `capacity_type` | `string` | — | `ON_DEMAND` or `SPOT` |
| `instance_types` | `list(string)` | — | 1 to 20 types |
| `scaling` | `object` | — | `min_size`, `desired_size`, `max_size` |
| `max_unavailable` | `number` | `1` | Nodes unavailable during an update |
| `root_volume` | `object` | — | `size_gib` (at least 20), `kms_key_arn`, `device_name` (`/dev/xvda`) |
| `metadata_hop_limit` | `number` | `1` | `1` or `2` |
| `labels` | `map(string)` | `{}` | Kubernetes labels |
| `taints` | `list(object)` | `[]` | `key`, `value`, `effect` |
| `node_repair_enabled` | `bool` | `true` | Automatic node repair |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`node_group_arn`, `node_group_id`, `node_group_name`, `launch_template_id`,
`launch_template_version`, `autoscaling_group_names`.

## Example

```hcl
module "system_node_group" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//eks-node-group?ref=eks-node-group-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client               = var.client
  project              = var.project
  environment          = var.environment
  cluster_name         = module.eks_cluster.cluster_name
  node_group_name      = "${local.governance_prefix}-ng-system"
  launch_template_name = "${local.governance_prefix}-lt-system"
  node_role_arn        = module.node_role.role_arn
  subnet_ids           = values(module.network.private_subnet_ids)
  security_group_ids   = []
  kubernetes_version   = var.kubernetes_version
  release_version      = var.node_release_version
  ami_type             = "AL2023_x86_64_STANDARD"
  capacity_type        = "ON_DEMAND"
  instance_types       = var.system_instance_types
  scaling              = var.system_scaling
  root_volume          = { size_gib = 50 }

  depends_on = [module.node_role]
}
```
