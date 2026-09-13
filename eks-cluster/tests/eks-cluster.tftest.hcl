# Plan-time tests of the eks-cluster module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_resource "aws_eks_cluster" {
    defaults = {
      arn                   = "arn:aws:eks:us-east-1:123456789012:cluster/lex-mts-fdev-eks-main"
      endpoint              = "https://0123456789ABCDEF0123456789ABCDEF.gr7.us-east-1.eks.amazonaws.com"
      platform_version      = "eks.1"
      certificate_authority = [{ data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t" }]
      identity              = [{ oidc = [{ issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF" }] }]
    }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/eks/lex-mts-fdev-eks-main/cluster" }
  }
  mock_resource "aws_eks_access_entry" {
    defaults = { access_entry_arn = "arn:aws:eks:us-east-1:123456789012:access-entry/lex-mts-fdev-eks-main/role/123456789012/example/00000000-0000-0000-0000-000000000000" }
  }
}

variables {
  endpoint_public_access_cidrs = []
  client                       = "lex"
  project                      = "mts"
  environment                  = "fdev"
  cluster_name                 = "lex-mts-fdev-eks-main"
  kubernetes_version           = "1.35"
  cluster_role_arn             = "arn:aws:iam::123456789012:role/lex-mts-fdev-role-eks"
  subnet_ids                   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids           = []
  service_ipv4_cidr            = "172.20.0.0/16"
  secrets_kms_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  control_plane_log_group = {
    standard_name     = "lex-mts-fdev-cwl-eks"
    retention_in_days = 90
    kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000001"
  }
}

run "creates_a_private_cluster_with_encrypted_secrets_and_logs" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API" && !aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions
    error_message = "Access must go through access entries only, and the cluster creator must get no implicit administrator access."
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access && !aws_eks_cluster.this.vpc_config[0].endpoint_public_access
    error_message = "The API must be private by default."
  }

  assert {
    condition     = aws_eks_cluster.this.encryption_config[0].provider[0].key_arn == var.secrets_kms_key_arn && contains(aws_eks_cluster.this.encryption_config[0].resources, "secrets")
    error_message = "Kubernetes secrets must be encrypted with the given key."
  }

  assert {
    condition     = length(aws_eks_cluster.this.enabled_cluster_log_types) == 5 && contains(aws_eks_cluster.this.enabled_cluster_log_types, "audit")
    error_message = "All five control-plane log types must be on by default."
  }

  assert {
    condition     = aws_cloudwatch_log_group.control_plane.name == "/aws/eks/lex-mts-fdev-eks-main/cluster" && aws_cloudwatch_log_group.control_plane.retention_in_days == 90 && aws_cloudwatch_log_group.control_plane.kms_key_id == var.control_plane_log_group.kms_key_arn
    error_message = "The control-plane log group must be the one Amazon EKS writes to, with the given retention and key."
  }

  assert {
    condition     = aws_eks_cluster.this.deletion_protection && aws_eks_cluster.this.upgrade_policy[0].support_type == "STANDARD" && !aws_eks_cluster.this.bootstrap_self_managed_addons
    error_message = "Deletion protection, standard support, and managed add-ons only must be the defaults."
  }

  assert {
    condition     = aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr == "172.20.0.0/16" && aws_eks_cluster.this.kubernetes_network_config[0].ip_family == "ipv4"
    error_message = "The service CIDR must be the one the root sets."
  }

  assert {
    condition     = aws_eks_cluster.this.tags["Name"] == "lex-mts-fdev-eks-main" && aws_eks_cluster.this.tags["Environment"] == "fdev"
    error_message = "The cluster must carry its standard name and the governance tags."
  }
}

run "opens_the_public_endpoint_only_to_named_cidrs" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    endpoint_public_access       = true
    endpoint_public_access_cidrs = ["203.0.113.10/32"]
  }

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access && aws_eks_cluster.this.vpc_config[0].endpoint_private_access
    error_message = "A public endpoint must be added to the private one, not replace it."
  }

  assert {
    condition     = length(aws_eks_cluster.this.vpc_config[0].public_access_cidrs) == 1 && contains(aws_eks_cluster.this.vpc_config[0].public_access_cidrs, "203.0.113.10/32")
    error_message = "The public endpoint must admit only the named CIDR blocks."
  }
}

run "grants_cluster_and_namespace_scoped_access" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    access_entries = {
      admin = {
        principal_arn       = "arn:aws:iam::123456789012:role/lex-mts-shd-role-admin"
        policy_associations = { cluster_admin = { policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" } }
      }
      viewer = {
        principal_arn       = "arn:aws:iam::123456789012:role/lex-mts-shd-role-viewer"
        policy_associations = { view = { policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy", access_scope_type = "namespace", namespaces = ["todo"] } }
      }
      karpenter = {
        principal_arn = "arn:aws:iam::123456789012:role/lex-mts-fdev-role-karpnode"
        type          = "EC2_LINUX"
      }
    }
  }

  assert {
    condition     = length(aws_eks_access_entry.this) == 3 && aws_eks_access_entry.this["karpenter"].type == "EC2_LINUX" && aws_eks_access_entry.this["admin"].type == "STANDARD"
    error_message = "Every access entry must be created with its type."
  }

  assert {
    condition     = keys(aws_eks_access_policy_association.this) == ["admin/cluster_admin", "viewer/view"]
    error_message = "Each access policy must be associated once, and the node entry must get none."
  }

  assert {
    condition     = aws_eks_access_policy_association.this["admin/cluster_admin"].access_scope[0].type == "cluster" && aws_eks_access_policy_association.this["viewer/view"].access_scope[0].type == "namespace" && aws_eks_access_policy_association.this["viewer/view"].access_scope[0].namespaces == toset(["todo"])
    error_message = "Access scopes must be the cluster or the named namespaces."
  }
}

run "installs_network_addons_with_the_cluster_and_the_rest_after_compute" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    addons = {
      vpc-cni    = { addon_version = "v1.23.0-eksbuild.1", before_compute = true, configuration_values = "{\"enableNetworkPolicy\":\"true\"}" }
      kube-proxy = { addon_version = "v1.35.3-eksbuild.18", before_compute = true }
      coredns    = { addon_version = "v1.14.3-eksbuild.3" }
    }
    compute_ready = ["arn:aws:eks:us-east-1:123456789012:nodegroup/lex-mts-fdev-eks-main/lex-mts-fdev-ng-system/00000000-0000-0000-0000-000000000000"]
  }

  assert {
    condition     = keys(aws_eks_addon.before_compute) == ["kube-proxy", "vpc-cni"] && keys(aws_eks_addon.after_compute) == ["coredns"]
    error_message = "Network add-ons must install with the cluster, and CoreDNS after compute."
  }

  assert {
    condition     = aws_eks_addon.before_compute["vpc-cni"].resolve_conflicts_on_create == "OVERWRITE" && aws_eks_addon.before_compute["vpc-cni"].resolve_conflicts_on_update == "PRESERVE" && aws_eks_addon.before_compute["vpc-cni"].addon_version == "v1.23.0-eksbuild.1"
    error_message = "Add-ons must take over self-managed copies at creation, keep in-cluster changes on update, and stay at the pinned version."
  }

  assert {
    condition     = terraform_data.compute_ready.input == var.compute_ready
    error_message = "The compute gate must hold the values the root passes."
  }
}

run "rejects_a_public_endpoint_open_to_the_internet" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    endpoint_public_access       = true
    endpoint_public_access_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.endpoint_public_access_cidrs]
}

run "rejects_a_public_endpoint_without_allowed_cidrs" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    endpoint_public_access = true
  }

  expect_failures = [var.endpoint_public_access_cidrs]
}

run "rejects_an_access_policy_on_a_node_entry" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    access_entries = {
      nodes = {
        principal_arn       = "arn:aws:iam::123456789012:role/lex-mts-fdev-role-node"
        type                = "EC2_LINUX"
        policy_associations = { admin = { policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" } }
      }
    }
  }

  expect_failures = [var.access_entries]
}

run "rejects_a_cluster_in_one_subnet" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_a_service_cidr_wider_than_a_12" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    service_ipv4_cidr = "10.0.0.0/8"
  }

  expect_failures = [var.service_ipv4_cidr]
}

run "rejects_an_addon_without_a_pinned_version" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    addons = { coredns = { addon_version = "latest" } }
  }

  expect_failures = [var.addons]
}

run "rejects_control_plane_logs_that_never_expire" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    control_plane_log_group = {
      standard_name     = "lex-mts-fdev-cwl-eks"
      retention_in_days = 0
      kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000001"
    }
  }

  expect_failures = [var.control_plane_log_group]
}
