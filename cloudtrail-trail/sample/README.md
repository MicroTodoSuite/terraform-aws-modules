# cloudtrail-trail sample

Creates the trail `lex-mts-shd-ct-tfstate` and its log bucket
`lex-mts-shd-s3-cloudtrail-<account>` with local state, recording the object
events of one existing bucket. Fill `kms_key_arn` with a key whose policy
carries the statements the module README lists, and `recorded_bucket_name` with
the bucket to record, then:

```bash
terraform init
terraform plan
```

The log bucket is protected from destruction. Removing the sample takes a
reviewed change that lifts `prevent_destroy` first.
