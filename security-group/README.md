# security-group

A security group with its ingress and egress rules as separate
`aws_vpc_security_group_*_rule` resources, one source or destination each. This
is the practice the provider documentation recommends, and the module never mixes
it with in-line rules. It is the one module that may create security groups,
which PC-IAC-023 forbids in service modules; `iac-contracts.json` records it as
their owner.

A group with no egress rules has no egress. Terraform removes the default
allow-all rule that AWS creates.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `security_group_name` | `string` | — | Standard name, such as `lex-mts-eco-sg-nodes` |
| `description` | `string` | — | What the group protects; changing it replaces the group |
| `vpc_id` | `string` | — | VPC of the group |
| `ingress_rules`, `egress_rules` | `map(object)` | `{}` | Rules keyed by purpose: `description`, `ip_protocol`, ports unless `-1`, and one of `cidr_ipv4`, `prefix_list_id`, `referenced_security_group_id`, `self` |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`security_group_id`, `security_group_arn`, `security_group_name`.

## Example

```hcl
module "node_security_group" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//security-group?ref=security-group-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client              = var.client
  project             = var.project
  environment         = var.environment
  security_group_name = "${local.governance_prefix}-sg-nodes"
  description         = "Worker nodes of the cluster."
  vpc_id              = data.aws_vpc.main.id
  ingress_rules       = local.node_ingress_rules
  egress_rules        = local.node_egress_rules
}
```
