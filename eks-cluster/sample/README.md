# eks-cluster sample

Creates the private cluster `lex-mts-fdev-eks-sample` with vpc-cni and
kube-proxy, and CoreDNS gated on compute, with local state. Fill the role,
subnets, and keys in `terraform.tfvars` from the network and security roots
first:

```bash
terraform init
terraform plan
```
