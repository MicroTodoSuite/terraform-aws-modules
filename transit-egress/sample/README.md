# transit-egress sample

Creates the hub `lex-mts-shd-tgw-sample` with route tables for the `fdev`,
`fstg`, and `fprd` spokes, with local state. Fill the egress VPC's IDs in
`terraform.tfvars` from a `network` call first:

```bash
terraform init
terraform plan
```
