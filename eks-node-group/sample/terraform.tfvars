# Example configuration of the eks-node-group sample. Names are built in locals.tf (PC-IAC-026).
client                    = "lex"
project                   = "mts"
environment               = "fdev"
region                    = "us-east-1"
kubernetes_version        = "1.35"
release_version           = "1.35.6-20260801"
node_role_arn             = ""
subnet_ids                = []
cluster_security_group_id = ""
