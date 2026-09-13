# Name construction for the eks-cluster sample: a private cluster whose network add-ons
# install with it and whose CoreDNS waits for compute.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  cluster_name = "${local.governance_prefix}-eks-sample"

  service_ipv4_cidr = "172.20.0.0/16"

  control_plane_log_group = {
    standard_name     = "${local.governance_prefix}-cwl-ekssample"
    retention_in_days = 30
    kms_key_arn       = var.log_kms_key_arn
  }

  addons = {
    vpc-cni    = { addon_version = "v1.23.0-eksbuild.1", before_compute = true }
    kube-proxy = { addon_version = "v1.35.3-eksbuild.18", before_compute = true }
    coredns    = { addon_version = "v1.14.3-eksbuild.3" }
  }
}
