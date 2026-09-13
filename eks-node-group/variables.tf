# Inputs of the eks-node-group module. Names arrive built by the root (PC-IAC-025); the node
# role, the subnets, and any security groups are received (PC-IAC-023).
variable "client" {
  type        = string
  description = "Client code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.client))
    error_message = "The client code must be 2 to 10 lowercase letters or digits."
  }
}

variable "project" {
  type        = string
  description = "Project code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,15}$", var.project))
    error_message = "The project code must be 2 to 15 lowercase letters or digits."
  }
}

variable "environment" {
  type        = string
  description = "Environment code, from MTS-IAC-101."

  validation {
    condition     = contains(["shd", "eco", "fdev", "fstg", "fprd"], var.environment)
    error_message = "The environment must be one of shd, eco, fdev, fstg, or fprd."
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster the nodes join, from the eks-cluster module's cluster_name output."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.cluster_name)) && length(var.cluster_name) <= 28
    error_message = "The cluster name must be a standard name of at most 28 characters."
  }
}

variable "node_group_name" {
  type        = string
  description = "Standard name of the node group, such as lex-mts-fdev-ng-system. It is the Name tag and the prefix of the physical name, which gets a unique suffix so a replacement group can exist beside the old one."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.node_group_name)) && length(var.node_group_name) <= 28
    error_message = "The node group name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }
}

variable "launch_template_name" {
  type        = string
  description = "Standard name of the node group's launch template, such as lex-mts-fdev-lt-system."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.launch_template_name)) && length(var.launch_template_name) <= 28
    error_message = "The launch template name must be a standard name of at most 28 characters."
  }
}

variable "node_role_arn" {
  type        = string
  description = "ARN of the IAM role the nodes assume, from the iam-role module, with AmazonEKSWorkerNodePolicy and a container registry pull policy attached. Amazon EKS creates the node access entry itself."

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", var.node_role_arn))
    error_message = "The node role must be an IAM role ARN."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets the nodes launch in."

  validation {
    condition     = length(var.subnet_ids) > 0 && alltrue([for id in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "At least one private subnet ID is required."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for the nodes, set in the launch template; [] lets Amazon EKS apply the cluster security group. Setting any replaces that group, so include rules that let the nodes reach the control plane."

  validation {
    condition     = alltrue([for id in var.security_group_ids : can(regex("^sg-[0-9a-f]+$", id))])
    error_message = "Every security group ID must look like sg-0123456789abcdef0."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes minor version of the nodes, the cluster's version or one minor behind during an upgrade."

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "The Kubernetes version must be a minor version such as 1.35."
  }
}

variable "release_version" {
  type        = string
  description = "Explicit AMI release of the nodes, such as 1.35.6-20260801. Raising it rolls the nodes; it never changes silently."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+-[0-9a-z]+$", var.release_version))
    error_message = "The release version must be an explicit AMI release such as 1.35.6-20260801."
  }
}

variable "ami_type" {
  type        = string
  description = "Amazon EKS optimized AMI type for Linux nodes, such as AL2023_x86_64_STANDARD. Changing it replaces the group."

  validation {
    condition = contains([
      "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "AL2023_x86_64_NEURON", "AL2023_x86_64_NVIDIA", "AL2023_ARM_64_NVIDIA",
      "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64_FIPS", "BOTTLEROCKET_ARM_64_FIPS",
      "BOTTLEROCKET_x86_64_NVIDIA", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA_FIPS", "BOTTLEROCKET_ARM_64_NVIDIA_FIPS",
    ], var.ami_type)
    error_message = "The AMI type must be an Amazon Linux 2023 or Bottlerocket type; custom AMIs are not supported by this module."
  }
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT. Changing it replaces the group."

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "The capacity type must be ON_DEMAND or SPOT."
  }
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types of the nodes, 1 to 20; several for SPOT. They are set on the node group, never in the launch template."

  validation {
    condition     = length(var.instance_types) >= 1 && length(var.instance_types) <= 20 && alltrue([for type in var.instance_types : can(regex("^[a-z0-9-]+\\.[a-z0-9]+$", type))])
    error_message = "Give 1 to 20 instance types such as m7i-flex.large."
  }
}

variable "scaling" {
  type = object({
    min_size     = number
    desired_size = number
    max_size     = number
  })
  description = "Node counts: min_size <= desired_size <= max_size, and max_size at least 1."

  validation {
    condition = (
      alltrue([for size in values(var.scaling) : size >= 0 && floor(size) == size]) &&
      var.scaling.min_size <= var.scaling.desired_size && var.scaling.desired_size <= var.scaling.max_size && var.scaling.max_size >= 1
    )
    error_message = "Sizes must be whole numbers with 0 <= min_size <= desired_size <= max_size and max_size >= 1."
  }
}

variable "max_unavailable" {
  type        = number
  description = "Nodes that may be unavailable at once while the group updates."
  default     = 1

  validation {
    condition     = var.max_unavailable >= 1 && floor(var.max_unavailable) == var.max_unavailable
    error_message = "max_unavailable must be a whole number of at least 1."
  }
}

variable "root_volume" {
  type = object({
    size_gib    = number
    kms_key_arn = optional(string)
    device_name = optional(string, "/dev/xvda")
  })
  description = "The nodes' gp3 root volume, always encrypted: its size in GiB, the KMS key (null for the AWS managed EBS key), and its device name."

  validation {
    condition     = var.root_volume.size_gib >= 20 && floor(var.root_volume.size_gib) == var.root_volume.size_gib
    error_message = "The root volume must be a whole number of GiB, at least 20."
  }

  validation {
    condition     = (var.root_volume.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.root_volume.kms_key_arn))) && can(regex("^/dev/[a-z0-9]+$", var.root_volume.device_name))
    error_message = "The root volume key must be null or a KMS key ARN, and its device name a /dev path."
  }
}

variable "metadata_hop_limit" {
  type        = number
  description = "Hop limit of IMDSv2 responses. 1 keeps the instance metadata service out of reach of pods, which get AWS credentials through their service accounts; 2 lets containers reach it."
  default     = 1

  validation {
    condition     = contains([1, 2], var.metadata_hop_limit)
    error_message = "The metadata hop limit must be 1 or 2."
  }
}

variable "labels" {
  type        = map(string)
  description = "Kubernetes labels on every node."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.labels) : length(key) > 0])
    error_message = "Label keys must not be empty."
  }
}

variable "taints" {
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  description = "Kubernetes taints on every node, at most 50."
  default     = []

  validation {
    condition     = length(var.taints) <= 50 && alltrue([for taint in var.taints : length(taint.key) > 0 && length(taint.key) <= 63 && contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)])
    error_message = "At most 50 taints, each with a key of 1 to 63 characters and an effect of NO_SCHEDULE, NO_EXECUTE, or PREFER_NO_SCHEDULE."
  }
}

variable "node_repair_enabled" {
  type        = bool
  description = "Whether Amazon EKS repairs unhealthy nodes automatically."
  default     = true
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to every resource besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
