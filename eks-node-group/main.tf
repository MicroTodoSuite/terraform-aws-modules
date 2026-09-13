# One EKS managed node group and the launch template it launches from: IMDSv2 only, an
# encrypted gp3 root volume, and tags on the instances, volumes, and network interfaces.
# The template sets nothing Amazon EKS forbids there: no subnet, no instance profile, no
# shutdown behavior, and no instance type, which stays on the node group.
resource "aws_launch_template" "this" {
  provider = aws.project

  name                   = var.launch_template_name
  description            = "Launch template of node group ${var.node_group_name}"
  update_default_version = true
  vpc_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : null

  block_device_mappings {
    device_name = var.root_volume.device_name

    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.root_volume.kms_key_arn
      volume_size           = var.root_volume.size_gib
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_hop_limit
    instance_metadata_tags      = "disabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.node_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.node_tags
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = local.node_tags
  }

  tags = merge(local.base_tags, { Name = var.launch_template_name })
}

resource "aws_eks_node_group" "this" {
  provider = aws.project

  cluster_name           = var.cluster_name
  node_group_name_prefix = "${var.node_group_name}-"
  node_role_arn          = var.node_role_arn
  subnet_ids             = var.subnet_ids
  version                = var.kubernetes_version
  release_version        = var.release_version
  ami_type               = var.ami_type
  capacity_type          = var.capacity_type
  instance_types         = var.instance_types
  labels                 = var.labels

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  scaling_config {
    min_size     = var.scaling.min_size
    desired_size = var.scaling.desired_size
    max_size     = var.scaling.max_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  node_repair_config {
    enabled = var.node_repair_enabled
  }

  dynamic "taint" {
    for_each = var.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(local.base_tags, { Name = var.node_group_name })

  # A change that replaces the group creates the new one first, under a new unique
  # suffix, so the cluster never loses all of this group's capacity at once.
  lifecycle {
    create_before_destroy = true
  }
}
