# The eks-cluster sample: one call of the module, fed from locals.
module "eks_cluster" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client                       = var.client
  project                      = var.project
  environment                  = var.environment
  cluster_name                 = local.cluster_name
  kubernetes_version           = var.kubernetes_version
  cluster_role_arn             = var.cluster_role_arn
  subnet_ids                   = var.subnet_ids
  security_group_ids           = []
  endpoint_public_access_cidrs = []
  service_ipv4_cidr            = local.service_ipv4_cidr
  secrets_kms_key_arn          = var.secrets_kms_key_arn
  control_plane_log_group      = local.control_plane_log_group
  addons                       = local.addons
}
