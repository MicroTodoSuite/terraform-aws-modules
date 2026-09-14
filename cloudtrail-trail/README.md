# cloudtrail-trail

A CloudTrail trail that records the S3 object-level data events of the buckets
a root names, and the private bucket that receives its logs. It exists so that
every read and write of the Terraform state bucket is recorded (ai-agents
specs/001 T043).

| Resource | Purpose |
| --- | --- |
| `aws_cloudtrail` | Records `Data` events of type `AWS::S3::Object` under the root's object ARN prefixes, encrypts with the root's customer key, and validates every log file with digest files |
| `aws_s3_bucket` | The log bucket, `<bucket_name>-<account>`, protected from destruction |
| `aws_s3_bucket_ownership_controls` | `BucketOwnerEnforced`: ACLs off |
| `aws_s3_bucket_public_access_block` | Every public access setting blocked |
| `aws_s3_bucket_versioning` | Versioned, so a deleted or overwritten log file survives as a version |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-KMS with the root's key; SSE-C uploads blocked |
| `aws_s3_bucket_lifecycle_configuration` | Expires log files and their old versions after the root's retention |
| `aws_s3_bucket_policy` | Lets only this trail read the ACL and write under `AWSLogs/<account>/`, and denies every request made without TLS |

## Design choices

- **A trail, not a CloudTrail Lake event data store.** An event data store
  needs no bucket, but AWS moved CloudTrail Lake to maintenance on 2026-04-30:
  it is closed to new customers.
- **Data events only.** The trail records no management events and is not
  multi-Region: it exists to record access to named buckets, which live in one
  Region. Trivy reports AWS-0014 (MEDIUM) for that; the gate fails only on HIGH
  and CRITICAL.
- **No S3 Bucket Key.** With one, CloudTrail would also need `kms:Decrypt` on
  the key to create the trail. A trail recording a single bucket writes too few
  objects for the saved KMS requests to matter.
- **Never its own bucket.** A precondition refuses an object prefix inside the
  log bucket: the trail would record each of its own deliveries and deliver
  that record again.
- **No access logs on the log bucket.** SonarCloud `terraform:S6258` is
  accepted in `docs/iac-exceptions.md`: server access logs would need a further
  bucket raising the same finding.

## The key policy the root must write

The module takes the key, it does not create it. Following the CloudTrail User
Guide ("Configure AWS KMS key policies for CloudTrail"), the key policy needs:

| Statement | Principal | Actions | Condition |
| --- | --- | --- | --- |
| Encrypt log files | `cloudtrail.amazonaws.com` | `kms:GenerateDataKey*` | `aws:SourceArn` equals the trail ARN; `kms:EncryptionContext:aws:cloudtrail:arn` like `arn:<partition>:cloudtrail:*:<account>:trail/*` |
| Describe the key | `cloudtrail.amazonaws.com` | `kms:DescribeKey` | `aws:SourceArn` equals the trail ARN |
| Read the logs | the account's IAM principals, by the usual account-root delegation | `kms:Decrypt` | granted in IAM, not in the key policy |

The trail ARN is `arn:<partition>:cloudtrail:<region>:<account>:trail/<trail_name>`,
known before the trail exists.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101) |
| `trail_name` | Standard name of the trail, validated against CloudTrail's naming rules |
| `bucket_name` | Standard name of the log bucket; the module appends the account ID |
| `kms_key_arn` | The customer key for log files, digest files, and the bucket |
| `s3_object_arn_prefixes` | Object ARN prefixes to record, each a bucket ARN followed by a slash |
| `log_retention` | `current_days` before a log file expires and `noncurrent_days` before an old version is removed |
| `additional_tags` | Tags besides `Name` and the provider's default tags |

Every name is built by the root (PC-IAC-025).

## Outputs

`trail_arn`, `trail_name`, `bucket_name` (with the account suffix), and
`bucket_arn`.

## Sample

`sample/` calls the module once with local state; see its README.
