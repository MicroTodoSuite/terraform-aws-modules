# state-backend

The S3 bucket and KMS key that hold every root's Terraform state
(PC-IAC-008). The bucket is private, versioned, and owned by its account. It
is encrypted with its own rotating customer-managed key, rejects uploads with
customer-provided keys, and denies any request made without TLS. Both the
bucket and the key carry `prevent_destroy` (PC-IAC-010).

Locking uses Terraform's native S3 lockfile (`use_lockfile = true` in each
root's backend configuration); there is no DynamoDB table.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `client`, `project`, `environment` | `string` | — | Governance codes (MTS-IAC-101), used for tags |
| `bucket_name` | `string` | — | Standard bucket name built by the root; the module appends `-<account ID>` |
| `kms_key_name` | `string` | — | Standard key name built by the root; becomes the Name tag and `alias/<name>` |
| `kms_deletion_window_in_days` | `number` | `30` | Days before a scheduled key deletion takes effect (7–30) |
| `additional_tags` | `map(string)` | `{}` | Extra tags; `Name` is reserved |

## Outputs

`bucket_name`, `bucket_arn`, `kms_key_arn`, `kms_key_id`, `kms_alias_name`.

## Example

```hcl
module "state_backend" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//state-backend?ref=state-backend-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  client       = var.client
  project      = var.project
  environment  = var.environment
  bucket_name  = "${local.governance_prefix}-s3-tfstate"
  kms_key_name = "${local.governance_prefix}-kms-tfstate"
}
```

`sample/` runs this call with local state.

## Destroying

The backend is not meant to be destroyed. A deliberate rebuild (MTS-IAC-107)
releases a version without `prevent_destroy`, destroys from a reviewed saved
plan after an external state backup, and restores the protection in the next
release.
