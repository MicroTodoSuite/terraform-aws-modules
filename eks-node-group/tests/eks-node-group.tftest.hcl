# Plan-time tests of the eks-node-group module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias           = "project"
  override_during = plan

  mock_resource "aws_launch_template" {
    defaults = { id = "lt-0123456789abcdef0", latest_version = 1 }
  }
  mock_resource "aws_eks_node_group" {
    defaults = {
      arn             = "arn:aws:eks:us-east-1:123456789012:nodegroup/lex-mts-fdev-eks-main/lex-mts-fdev-ng-system-20260912000000000000000001/00000000-0000-0000-0000-000000000000"
      id              = "lex-mts-fdev-eks-main:lex-mts-fdev-ng-system-20260912000000000000000001"
      node_group_name = "lex-mts-fdev-ng-system-20260912000000000000000001"
      resources       = []
    }
  }
}

variables {
  client               = "lex"
  project              = "mts"
  environment          = "fdev"
  cluster_name         = "lex-mts-fdev-eks-main"
  node_group_name      = "lex-mts-fdev-ng-system"
  launch_template_name = "lex-mts-fdev-lt-system"
  node_role_arn        = "arn:aws:iam::123456789012:role/lex-mts-fdev-role-node"
  subnet_ids           = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids   = []
  kubernetes_version   = "1.35"
  release_version      = "1.35.6-20260801"
  ami_type             = "AL2023_x86_64_STANDARD"
  capacity_type        = "ON_DEMAND"
  instance_types       = ["m7i-flex.large"]
  scaling              = { min_size = 2, desired_size = 2, max_size = 4 }
  root_volume          = { size_gib = 50 }
}

run "launches_from_a_template_with_imdsv2_and_an_encrypted_root_volume" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required" && aws_launch_template.this.metadata_options[0].http_put_response_hop_limit == 1 && aws_launch_template.this.metadata_options[0].instance_metadata_tags == "disabled"
    error_message = "Nodes must require IMDSv2 and keep the metadata service out of reach of pods."
  }

  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].device_name == "/dev/xvda" && aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == "true" && aws_launch_template.this.block_device_mappings[0].ebs[0].volume_type == "gp3" && aws_launch_template.this.block_device_mappings[0].ebs[0].volume_size == 50
    error_message = "The root volume must be an encrypted gp3 volume of the given size."
  }

  assert {
    condition     = length(aws_launch_template.this.tag_specifications) == 3 && aws_launch_template.this.tags["Name"] == "lex-mts-fdev-lt-system"
    error_message = "Instances, volumes, and network interfaces must be tagged, and the template must carry its standard name."
  }
}

run "creates_a_replaceable_node_group_at_pinned_versions" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_eks_node_group.this.node_group_name_prefix == "lex-mts-fdev-ng-system-" && aws_eks_node_group.this.tags["Name"] == "lex-mts-fdev-ng-system"
    error_message = "The physical name must be the standard name plus a unique suffix, and the Name tag the standard name."
  }

  assert {
    condition     = aws_eks_node_group.this.version == "1.35" && aws_eks_node_group.this.release_version == "1.35.6-20260801" && aws_eks_node_group.this.ami_type == "AL2023_x86_64_STANDARD"
    error_message = "The Kubernetes version, AMI release, and AMI type must be the pinned ones."
  }

  assert {
    condition     = aws_eks_node_group.this.launch_template[0].id == "lt-0123456789abcdef0" && aws_eks_node_group.this.launch_template[0].version == "1"
    error_message = "The node group must run the module's launch template at its latest version."
  }

  assert {
    condition     = aws_eks_node_group.this.scaling_config[0].min_size == 2 && aws_eks_node_group.this.scaling_config[0].desired_size == 2 && aws_eks_node_group.this.scaling_config[0].max_size == 4 && aws_eks_node_group.this.update_config[0].max_unavailable == 1
    error_message = "Scaling and update settings must be the given ones."
  }

  assert {
    condition     = aws_eks_node_group.this.node_repair_config[0].enabled && aws_eks_node_group.this.capacity_type == "ON_DEMAND" && aws_eks_node_group.this.instance_types == tolist(["m7i-flex.large"])
    error_message = "Node repair must be on, and capacity type and instance types must be set on the node group."
  }
}

run "sets_custom_security_groups_labels_and_taints" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    security_group_ids = ["sg-0123456789abcdef0", "sg-0123456789abcdef1"]
    labels             = { "microtodosuite.io/capacity-owner" = "managed-node-group" }
    taints             = [{ key = "dedicated", value = "system", effect = "NO_SCHEDULE" }]
  }

  assert {
    condition     = aws_launch_template.this.vpc_security_group_ids == toset(["sg-0123456789abcdef0", "sg-0123456789abcdef1"])
    error_message = "Given security groups must be set in the launch template."
  }

  assert {
    condition     = aws_eks_node_group.this.labels["microtodosuite.io/capacity-owner"] == "managed-node-group" && length(aws_eks_node_group.this.taint) == 1 && one(aws_eks_node_group.this.taint[*].effect) == "NO_SCHEDULE"
    error_message = "Labels and taints must reach the node group."
  }
}

run "rejects_a_desired_size_above_the_maximum" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    scaling = { min_size = 1, desired_size = 5, max_size = 4 }
  }

  expect_failures = [var.scaling]
}

run "rejects_a_root_volume_under_20_gib" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    root_volume = { size_gib = 8 }
  }

  expect_failures = [var.root_volume]
}

run "rejects_a_metadata_hop_limit_above_two" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    metadata_hop_limit = 3
  }

  expect_failures = [var.metadata_hop_limit]
}

run "rejects_a_custom_ami_type" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    ami_type = "CUSTOM"
  }

  expect_failures = [var.ami_type]
}

run "rejects_an_unknown_taint_effect" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    taints = [{ key = "dedicated", effect = "NoSchedule" }]
  }

  expect_failures = [var.taints]
}
