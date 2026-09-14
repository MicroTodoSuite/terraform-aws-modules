# Infrastructure-as-Code Exceptions

Findings of the rule contracts, tflint, Trivy, or SonarCloud that the team has
decided to accept. A row waives a contract finding only when it carries a
reason and an expiry; the format is defined in
`microservice-app-ai-agents/rules/iac/README.md`. Rows for tflint, Trivy, and
SonarCloud record the decision behind a suppression made in that tool or in
the code (`NOSONAR`, `.trivyignore`), which must cite the row. Each row is added
in its own reviewed pull request.

| Rule | Path | Resource | Reason | Expiry |
| --- | --- | --- | --- | --- |
| SonarCloud `terraform:S6258` | state-backend | aws_s3_bucket.this | The state bucket denies every request made without TLS, encrypts with its own rotating KMS key, blocks all public access, enforces bucket-owner ownership, and is reachable only by IAM principals of the declared account. S3 server access logs would need a second bucket that raises the same finding. Maintainer decision, 2026-09-13. | When CloudTrail data events record access to the state bucket (ai-agents specs/001 T043) |
| SonarCloud `terraform:S6258` | cloudtrail-trail | aws_s3_bucket.this | The bucket receives only its own trail's log and digest files. Its policy lets `cloudtrail.amazonaws.com` read the bucket ACL and write under `AWSLogs/<account>/` only for that trail's ARN, and denies every request made without TLS; it is versioned, encrypted with a customer KMS key, blocks all public access, and enforces bucket-owner ownership, and the trail validates every log file with digest files. S3 server access logs would need a further bucket that raises the same finding, and a trail cannot record data events on its own log bucket without recording its own deliveries in a loop. Decided by the maintainer's delegate, 2026-09-14 (ai-agents specs/001 T043). | When the account's audit logs move to a dedicated log archive account whose own trail records access to this bucket |
