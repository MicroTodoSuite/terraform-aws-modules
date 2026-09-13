# iam-oidc-provider

An IAM OpenID Connect provider, such as the GitHub Actions issuer that the CI
roles trust. An account holds exactly one provider per issuer URL, so the
shared root owns it and every role references it by ARN.

No thumbprint is configured. For GitHub, and for the other identity providers
AWS lists, IAM validates the issuer's certificate against its own library of
trusted root certificate authorities, and a configured thumbprint is ignored
(`aws_iam_openid_connect_provider` documentation).

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `url` | `string` | — | Issuer URL, `https` only |
| `client_ids` | `list(string)` | — | Accepted audiences |
| `standard_name` | `string` | — | Name tag, such as `lex-mts-shd-oidc-github` |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`provider_arn`, `provider_url`.

## Example

```hcl
module "github_oidc" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//iam-oidc-provider?ref=iam-oidc-provider-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client        = var.client
  project       = var.project
  environment   = var.environment
  url           = "https://token.actions.githubusercontent.com"
  client_ids    = ["sts.amazonaws.com"]
  standard_name = "${local.governance_prefix}-oidc-github"
}
```

An existing provider is adopted with an `import` block in the root.
