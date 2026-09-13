# network sample

Plans a two-zone VPC with one NAT gateway and encrypted flow logs, with local state.
The flow-log key and role come from variables:

```bash
terraform init
terraform plan -var flow_log_kms_key_arn=<key ARN> -var flow_log_role_arn=<role ARN>
```
