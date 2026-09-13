# Inputs of the state-backend module. Names arrive built by the root (PC-IAC-025).
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

variable "bucket_name" {
  type        = string
  description = "Standard name of the state bucket, such as lex-mts-shd-s3-tfstate. The module appends the account ID, which keeps the global name unique (PC-IAC-008)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$", var.bucket_name))
    error_message = "The bucket name must be 3 to 50 lowercase letters, digits, or hyphens, leaving room for the account suffix within the 63 characters S3 allows."
  }
}

variable "kms_key_name" {
  type        = string
  description = "Standard name of the state encryption key, such as lex-mts-shd-kms-tfstate. It becomes the key's Name tag and its alias."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,62}$", var.kms_key_name))
    error_message = "The key name must be at most 63 lowercase letters, digits, or hyphens."
  }
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "Days AWS KMS waits before deleting the key once its deletion is scheduled."
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "The deletion window must be between 7 and 30 days, the range AWS KMS accepts."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the bucket and the key besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
