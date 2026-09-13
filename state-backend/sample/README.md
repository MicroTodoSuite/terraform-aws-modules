# state-backend sample

Creates `lex-mts-shd-s3-tfstate-<account ID>` and its key with local state. The
bucket and key carry `prevent_destroy`, so the sample is meant to be planned,
not applied, outside a deliberate bootstrap:

```bash
terraform init
terraform plan
```
