# route53-zone

A public Route 53 hosted zone. The zone's name is the domain itself, and its
`Name` tag follows the standard pattern (MTS-IAC-101). The zone:
- sets `force_destroy = false`, so it never deletes records managed elsewhere;
- carries `prevent_destroy` (PC-IAC-010), because losing it breaks the
  registrar's delegation.

Records belong to the roots that own their targets; this module creates none.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes, used for tags |
| `zone_name` | `string` | — | Domain the zone serves |
| `standard_name` | `string` | — | Name tag, such as `lex-mts-shd-dns-public` |
| `comment` | `string` | a delegation note | Comment on the zone |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`zone_id`, `zone_arn`, `zone_name`, `name_server_names`.

## Example

```hcl
module "public_zone" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//route53-zone?ref=route53-zone-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client        = var.client
  project       = var.project
  environment   = var.environment
  zone_name     = var.public_domain
  standard_name = "${local.governance_prefix}-dns-public"
}
```

An existing zone is adopted with an `import` block in the root, never recreated.
