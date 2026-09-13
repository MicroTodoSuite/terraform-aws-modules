# Inputs of the route53-zone module.
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

variable "zone_name" {
  type        = string
  description = "Domain the public hosted zone serves, such as microtodosuite.abrdns.com. The zone's name is the domain (MTS-IAC-101)."

  validation {
    condition     = can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}$", var.zone_name))
    error_message = "The zone name must be a lowercase domain name without a trailing dot."
  }
}

variable "standard_name" {
  type        = string
  description = "Standard name for the zone's Name tag, built by the root, such as lex-mts-shd-dns-public."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.standard_name)) && length(var.standard_name) <= 28
    error_message = "The standard name must be lowercase letters and digits separated by hyphens, at most 28 characters."
  }
}

variable "comment" {
  type        = string
  description = "Comment shown on the hosted zone."
  default     = "Public hosted zone; registrar delegation is managed outside Terraform."

  validation {
    condition     = length(var.comment) > 0 && length(var.comment) <= 256
    error_message = "The comment must be 1 to 256 characters."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the zone besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
