# ecr-repository

ECR repositories for container images, one per entry of `repositories`. Every
repository:
- has immutable tags;
- scans images on push;
- encrypts with AES-256;
- refuses deletion while it holds images;
- expires untagged images after `untagged_image_expiry_days`.

Each repository also carries `prevent_destroy` (PC-IAC-010), because it holds
released images.

Names are the standard names the root builds, without a path
(MTS-IAC-101): `lex-mts-shd-ecr-authapi`.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `repositories` | `map(object({ name = string }))` | — | Repositories keyed by service key |
| `untagged_image_expiry_days` | `number` | `30` | Days before an untagged image expires |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` and `Service` are reserved |

## Outputs

`repository_arns`, `repository_urls`, `repository_names`, each keyed like `repositories`.

## Example

```hcl
module "ecr" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//ecr-repository?ref=ecr-repository-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client       = var.client
  project      = var.project
  environment  = var.environment
  repositories = { for service in local.services : service => { name = "${local.governance_prefix}-ecr-${service}" } }
}
```
