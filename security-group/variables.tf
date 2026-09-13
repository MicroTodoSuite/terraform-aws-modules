# Inputs of the security-group module. The name arrives built by the root (PC-IAC-025).
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

variable "security_group_name" {
  type        = string
  description = "Standard name of the security group, such as lex-mts-eco-sg-nodes."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.security_group_name)) && length(var.security_group_name) <= 28
    error_message = "The name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }
}

variable "description" {
  type        = string
  description = "What the group protects. AWS cannot change a group's description, so changing it replaces the group."

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 255
    error_message = "The description must be 1 to 255 characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the group belongs to, from the networking root."

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "The VPC ID must look like vpc-0123456789abcdef0."
  }
}

variable "ingress_rules" {
  type = map(object({
    description                  = string
    ip_protocol                  = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  description = "Inbound rules keyed by a short purpose. Each has exactly one source: cidr_ipv4, prefix_list_id, referenced_security_group_id, or self."
  default     = {}

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      length(compact([rule.cidr_ipv4, rule.prefix_list_id, rule.referenced_security_group_id, rule.self ? "self" : null])) == 1
    ])
    error_message = "Every ingress rule needs exactly one source."
  }

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      length(rule.description) > 0 && (rule.ip_protocol == "-1" ? rule.from_port == null && rule.to_port == null : rule.from_port != null && rule.to_port != null)
    ])
    error_message = "Every ingress rule needs a description, and ports unless ip_protocol is -1 (all), which takes none."
  }
}

variable "egress_rules" {
  type = map(object({
    description                  = string
    ip_protocol                  = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    self                         = optional(bool, false)
  }))
  description = "Outbound rules keyed by a short purpose. Each has exactly one destination: cidr_ipv4, prefix_list_id, referenced_security_group_id, or self. No rule means no egress, because Terraform removes the default allow-all rule."
  default     = {}

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      length(compact([rule.cidr_ipv4, rule.prefix_list_id, rule.referenced_security_group_id, rule.self ? "self" : null])) == 1
    ])
    error_message = "Every egress rule needs exactly one destination."
  }

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) :
      length(rule.description) > 0 && (rule.ip_protocol == "-1" ? rule.from_port == null && rule.to_port == null : rule.from_port != null && rule.to_port != null)
    ])
    error_message = "Every egress rule needs a description, and ports unless ip_protocol is -1 (all), which takes none."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the group and its rules besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
