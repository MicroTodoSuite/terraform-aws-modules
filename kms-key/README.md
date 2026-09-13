# kms-key

A symmetric, regional, customer-managed KMS key and its alias. The key
rotates yearly by default and keeps a 30-day deletion window. The root
supplies the key policy as JSON, or leaves it empty for the AWS default policy,
which delegates access to IAM in the owning account.

The key carries no `prevent_destroy`, because environment keys go with their
environment. The Terraform state key is not made with this module: it lives in
`state-backend`, which protects it.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `key_name` | `string` | — | Standard name, the Name tag and `alias/<name>` |
| `description` | `string` | — | What the key encrypts |
| `policy` | `string` | `""` | Key policy JSON, or `""` for the AWS default |
| `deletion_window_in_days` | `number` | `30` | 7–30 |
| `enable_key_rotation` | `bool` | `true` | Yearly rotation |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`key_arn`, `key_id`, `alias_name`, `alias_arn`.

## Example

```hcl
module "flow_log_key" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//kms-key?ref=kms-key-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  key_name    = "${local.governance_prefix}-kms-flowlogs"
  description = "Encrypts the VPC flow-log groups."
  policy      = local.flow_log_key_policy
}
```
