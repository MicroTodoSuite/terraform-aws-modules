# eks-node-group sample

Creates the node group `lex-mts-fdev-ng-sample-<suffix>` and its launch
template in the cluster `lex-mts-fdev-eks-sample`, with local state. Create
the cluster with the `eks-cluster` sample first, and fill the node role and
subnets in `terraform.tfvars`:

```bash
terraform init
terraform plan
```
