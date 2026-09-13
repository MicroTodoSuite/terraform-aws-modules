# The eks-node-group sample: one call of the module, fed from locals.
module "eks_node_group" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client               = var.client
  project              = var.project
  environment          = var.environment
  cluster_name         = local.cluster_name
  node_group_name      = local.node_group_name
  launch_template_name = local.launch_template_name
  node_role_arn        = var.node_role_arn
  subnet_ids           = var.subnet_ids
  security_group_ids   = [var.cluster_security_group_id]
  kubernetes_version   = var.kubernetes_version
  release_version      = var.release_version
  ami_type             = "AL2023_x86_64_STANDARD"
  capacity_type        = "ON_DEMAND"
  instance_types       = ["m7i-flex.large"]
  scaling              = local.scaling
  root_volume          = local.root_volume
  labels               = local.labels
}
