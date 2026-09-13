# secret

A Secrets Manager secret. The container is protected from destruction,
because the lifecycle `down` preserves secrets and their values. The module can
optionally write a value through the write-only `secret_string_wo` argument,
fed from an ephemeral input, so the value never reaches the plan or the state
(PC-IAC-016). A human-supplied value, such as a webhook URL, is set outside
Terraform and leaves `secret_value_version` at `0`.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `secret_name` | `string` | — | Standard name, such as `lex-mts-eco-sm-jwtdev` |
| `description` | `string` | — | What the secret holds |
| `kms_key_arn` | `string` | — | Customer-managed key, or `""` for `aws/secretsmanager` |
| `recovery_window_in_days` | `number` | `30` | Days a deleted secret stays recoverable (7–30) |
| `secret_value` | `string`, ephemeral, sensitive | `null` | Value to write |
| `secret_value_version` | `number` | `0` | `0` writes nothing; raise it to write `secret_value` again |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`secret_arn`, `secret_name`. The value is never returned.

## Example

```hcl
module "jwt_dev" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//secret?ref=secret-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client               = var.client
  project              = var.project
  environment          = var.environment
  secret_name          = "${local.governance_prefix}-sm-jwtdev"
  description          = "JWT signing key of the dev namespace, read by External Secrets."
  kms_key_arn          = ""
  secret_value         = ephemeral.random_password.jwt_dev.result
  secret_value_version = 1
}
```
