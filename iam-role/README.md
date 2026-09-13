# iam-role

An IAM role with its trust policy, inline permission policies, and managed
policy attachments. The consuming root builds every policy document as JSON,
because the principals and resources it names belong to the root's domain.

This is the one module that may create IAM roles and policies. PC-IAC-023
forbids them in service modules, and `iac-contracts.json` records this module
as their owner.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `role_name` | `string` | — | Standard role name, such as `lex-mts-shd-role-ecrpublish` |
| `description` | `string` | — | What the role is for |
| `assume_role_policy` | `string` | — | Trust policy JSON |
| `inline_policies` | `map(string)` | `{}` | Inline policy JSON keyed by policy name |
| `managed_policy_arns` | `set(string)` | — | Managed policies to attach; `[]` for none |
| `permissions_boundary_arn` | `string` | — | Boundary ARN, or `""` for none |
| `max_session_duration` | `number` | `3600` | Session length limit in seconds |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`role_arn`, `role_name`.

## Example

```hcl
module "ecr_publisher_role" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//iam-role?ref=iam-role-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client                   = var.client
  project                  = var.project
  environment              = var.environment
  role_name                = "${local.governance_prefix}-role-ecrpublish"
  description              = "Publishes reviewed images from main to ECR."
  assume_role_policy       = local.github_publisher_trust_policy
  inline_policies          = { "publish-images" = local.ecr_publish_policy }
  managed_policy_arns      = []
  permissions_boundary_arn = ""
}
```
