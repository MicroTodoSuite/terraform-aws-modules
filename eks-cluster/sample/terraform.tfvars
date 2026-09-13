# Example configuration of the eks-cluster sample. Names are built in locals.tf (PC-IAC-026).
client              = "lex"
project             = "mts"
environment         = "fdev"
region              = "us-east-1"
kubernetes_version  = "1.35"
cluster_role_arn    = ""
subnet_ids          = []
secrets_kms_key_arn = ""
log_kms_key_arn     = ""
