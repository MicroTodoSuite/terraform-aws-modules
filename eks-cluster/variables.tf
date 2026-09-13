# Inputs of the eks-cluster module. Names arrive built by the root (PC-IAC-025); the IAM
# role, the KMS keys, the subnets, and any extra security groups are received (PC-IAC-023).
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
  description = "Standard name of the cluster, such as lex-mts-fdev-eks-main. It also names the control-plane log group /aws/eks/<name>/cluster."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.cluster_name)) && length(var.cluster_name) <= 28
    error_message = "The cluster name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes minor version, such as 1.35. Choose one in standard support on the Amazon EKS release calendar; raising it upgrades the control plane, and EKS never downgrades."

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "The Kubernetes version must be a minor version such as 1.35."
  }
}

variable "support_type" {
  type        = string
  description = "What happens at the end of standard support: STANDARD upgrades the cluster automatically; EXTENDED keeps the version at the extended-support price."
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.support_type)
    error_message = "The support type must be STANDARD or EXTENDED."
  }
}

variable "cluster_role_arn" {
  type        = string
  description = "ARN of the IAM role the control plane assumes, from the iam-role module. Attach AmazonEKSClusterPolicy to it before calling this module, so the policy outlives the cluster on destroy."

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", var.cluster_role_arn))
    error_message = "The cluster role must be an IAM role ARN."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for the control plane's network interfaces, in at least two Availability Zones."

  validation {
    condition     = length(var.subnet_ids) >= 2 && alltrue([for id in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "At least two subnet IDs are required, in two Availability Zones, as Amazon EKS requires."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups added to the control plane's network interfaces, besides the cluster security group Amazon EKS creates; [] for none."

  validation {
    condition     = alltrue([for id in var.security_group_ids : can(regex("^sg-[0-9a-f]+$", id))])
    error_message = "Every security group ID must look like sg-0123456789abcdef0."
  }
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the Kubernetes API also has a public endpoint. The private endpoint is always on."
  default     = false
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the public endpoint: at least one when it is on, [] when it is off. Operator addresses belong in gitignored .tfvars."

  validation {
    condition     = alltrue([for cidr in var.endpoint_public_access_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "Every public endpoint CIDR must be a valid IPv4 block narrower than /0; the API is never open to the whole internet."
  }

  validation {
    condition     = var.endpoint_public_access ? length(var.endpoint_public_access_cidrs) > 0 : length(var.endpoint_public_access_cidrs) == 0
    error_message = "A public endpoint needs at least one allowed CIDR block, and a private-only cluster takes none."
  }
}

variable "service_ipv4_cidr" {
  type        = string
  description = "CIDR block for Kubernetes service addresses, fixed at creation: between /24 and /12, inside 10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16, and overlapping neither the VPC nor any network it reaches. Set explicitly so no environment inherits whichever default Amazon EKS picks."

  validation {
    condition     = can(cidrhost(var.service_ipv4_cidr, 0)) && try(tonumber(split("/", var.service_ipv4_cidr)[1]) >= 12 && tonumber(split("/", var.service_ipv4_cidr)[1]) <= 24, false)
    error_message = "The service CIDR must be a valid IPv4 block between /24 and /12."
  }
}

variable "secrets_kms_key_arn" {
  type        = string
  description = "ARN of the symmetric KMS key, in the cluster's region, that encrypts Kubernetes secrets (kms-key module)."

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.secrets_kms_key_arn))
    error_message = "The secrets key must be a KMS key ARN."
  }
}

variable "enabled_log_types" {
  type        = list(string)
  description = "Control-plane log types sent to CloudWatch Logs. All five by default."
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = length(var.enabled_log_types) > 0 && alltrue([for type in var.enabled_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], type)])
    error_message = "Log types must be among api, audit, authenticator, controllerManager, and scheduler, and at least one is required."
  }
}

variable "control_plane_log_group" {
  type = object({
    standard_name     = string
    retention_in_days = number
    kms_key_arn       = string
  })
  description = "The control-plane log group: its standard name for the Name tag (its physical name is set by Amazon EKS), a finite retention in days, and the KMS key that encrypts it. The key policy must let CloudWatch Logs use the key."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.control_plane_log_group.standard_name)) && length(var.control_plane_log_group.standard_name) <= 28
    error_message = "The log group needs a standard name of at most 28 characters."
  }

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.control_plane_log_group.retention_in_days)
    error_message = "The retention must be one of the values CloudWatch Logs accepts; never-expire (0) is not offered."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.control_plane_log_group.kms_key_arn))
    error_message = "The log group key must be a KMS key ARN."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Whether Amazon EKS refuses to delete the cluster. Turn it off in a reviewed change before a planned teardown."
  default     = true
}

variable "bootstrap_self_managed_addons" {
  type        = bool
  description = "Whether Amazon EKS installs self-managed vpc-cni, kube-proxy, and CoreDNS at creation. Off: the add-ons come from var.addons as managed add-ons. Changing it replaces the cluster."
  default     = false
}

variable "access_entries" {
  type = map(object({
    principal_arn     = string
    type              = optional(string, "STANDARD")
    kubernetes_groups = optional(list(string), [])
    policy_associations = optional(map(object({
      policy_arn        = string
      access_scope_type = optional(string, "cluster")
      namespaces        = optional(list(string), [])
    })), {})
  }))
  description = "IAM principals allowed into the Kubernetes API, keyed by a short key. A STANDARD entry takes Kubernetes groups and EKS access policies scoped to the cluster or to namespaces; an EC2_LINUX, EC2_WINDOWS, or FARGATE_LINUX entry takes neither. The cluster creator gets no implicit access."
  default     = {}

  validation {
    condition = alltrue([
      for entry in values(var.access_entries) :
      can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:(role|user)/.+$", entry.principal_arn)) && contains(["STANDARD", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX"], entry.type)
    ])
    error_message = "Every access entry needs an IAM role or user ARN and a type of STANDARD, EC2_LINUX, EC2_WINDOWS, or FARGATE_LINUX."
  }

  validation {
    condition = alltrue([
      for entry in values(var.access_entries) :
      entry.type == "STANDARD" || (length(entry.kubernetes_groups) == 0 && length(entry.policy_associations) == 0)
    ])
    error_message = "Only a STANDARD access entry takes Kubernetes groups or access policies; Amazon EKS refuses both on node and Fargate entries."
  }

  validation {
    condition = alltrue(flatten([
      for entry in values(var.access_entries) : [
        for policy in values(entry.policy_associations) :
        can(regex("^arn:aws[a-z-]*:eks::aws:cluster-access-policy/[A-Za-z0-9]+$", policy.policy_arn)) && (
          policy.access_scope_type == "cluster" ? length(policy.namespaces) == 0 : (policy.access_scope_type == "namespace" && length(policy.namespaces) > 0)
        )
      ]
    ]))
    error_message = "Every access policy needs an EKS cluster-access-policy ARN and a cluster scope without namespaces or a namespace scope with at least one namespace."
  }
}

variable "addons" {
  type = map(object({
    addon_version               = string
    before_compute              = optional(bool, false)
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_update = optional(string, "PRESERVE")
  }))
  description = "Amazon EKS managed add-ons keyed by add-on name, each at a pinned version. before_compute = true installs it with the cluster (vpc-cni, kube-proxy); the others wait for var.compute_ready, because their pods need nodes (coredns, aws-ebs-csi-driver)."
  default     = {}

  validation {
    condition     = alltrue([for addon in values(var.addons) : can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+-eksbuild\\.[0-9]+$", addon.addon_version))])
    error_message = "Every add-on needs a pinned version such as v1.14.3-eksbuild.3."
  }

  validation {
    condition = alltrue([
      for addon in values(var.addons) :
      (addon.service_account_role_arn == null || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+$", addon.service_account_role_arn))) &&
      (addon.configuration_values == null || can(jsondecode(addon.configuration_values))) &&
      contains(["NONE", "OVERWRITE", "PRESERVE"], addon.resolve_conflicts_on_update)
    ])
    error_message = "An add-on's service account role must be an IAM role ARN, its configuration values JSON, and its update conflict resolution NONE, OVERWRITE, or PRESERVE."
  }
}

variable "compute_ready" {
  type        = list(string)
  description = "Values that exist only once the cluster has nodes, such as the eks-node-group module's node_group_arn. The add-ons with before_compute = false wait for them; [] when there are none."
  default     = []

  validation {
    condition     = alltrue([for value in var.compute_ready : length(value) > 0])
    error_message = "Compute-ready values must not be empty strings."
  }
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
