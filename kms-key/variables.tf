# Inputs of the kms-key module. The name arrives built by the root (PC-IAC-025).
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

variable "key_name" {
  type        = string
  description = "Standard name of the key, such as lex-mts-shd-kms-flowlogs. It becomes the Name tag and the alias alias/<name>."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.key_name)) && length(var.key_name) <= 28
    error_message = "The key name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }
}

variable "description" {
  type        = string
  description = "What the key encrypts, shown in AWS KMS."

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 8192
    error_message = "The description must be 1 to 8192 characters."
  }
}

variable "policy" {
  type        = string
  description = "Key policy as JSON, or an empty string for the AWS default key policy, which delegates access to IAM in the owning account."
  default     = ""

  validation {
    condition     = var.policy == "" || can(jsondecode(var.policy).Statement)
    error_message = "The key policy must be empty or a JSON policy document with a Statement."
  }
}

variable "deletion_window_in_days" {
  type        = number
  description = "Days AWS KMS waits before deleting the key once its deletion is scheduled."
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "The deletion window must be between 7 and 30 days, the range AWS KMS accepts."
  }
}

variable "enable_key_rotation" {
  type        = bool
  description = "Whether AWS KMS rotates the key material yearly. Disable only for a key type that cannot rotate."
  default     = true
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the key besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
