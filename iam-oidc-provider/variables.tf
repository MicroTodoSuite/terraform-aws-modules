# Inputs of the iam-oidc-provider module.
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

variable "url" {
  type        = string
  description = "Issuer URL of the identity provider, such as https://token.actions.githubusercontent.com."

  validation {
    condition     = can(regex("^https://[a-z0-9.-]+(/[A-Za-z0-9._/-]*)?$", var.url))
    error_message = "The issuer URL must use https and contain no query or fragment."
  }
}

variable "client_ids" {
  type        = list(string)
  description = "Audiences accepted from the provider, such as sts.amazonaws.com."

  validation {
    condition     = length(var.client_ids) > 0 && alltrue([for client_id in var.client_ids : length(client_id) > 0])
    error_message = "At least one non-empty client ID is required."
  }
}

variable "standard_name" {
  type        = string
  description = "Standard name for the provider's Name tag, built by the root, such as lex-mts-shd-oidc-github. The provider's own name is its issuer URL (MTS-IAC-101)."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.standard_name)) && length(var.standard_name) <= 28
    error_message = "The standard name must be lowercase letters and digits separated by hyphens, at most 28 characters."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the provider besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
