# Inputs of the secret module. A value, when given, is ephemeral and never stored in state (PC-IAC-016).
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

variable "secret_name" {
  type        = string
  description = "Standard name of the secret, built by the root, such as lex-mts-eco-sm-jwtdev."

  validation {
    condition     = can(regex("^[A-Za-z0-9/_+=.@-]{1,512}$", var.secret_name))
    error_message = "The secret name must be 1 to 512 characters from the set Secrets Manager allows."
  }
}

variable "description" {
  type        = string
  description = "What the secret holds and who reads it."

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 2048
    error_message = "The description must be 1 to 2048 characters."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the customer-managed key that encrypts the secret, or an empty string for the account's aws/secretsmanager key."

  validation {
    condition     = var.kms_key_arn == "" || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_arn))
    error_message = "The key must be empty or a KMS key ARN."
  }
}

variable "recovery_window_in_days" {
  type        = number
  description = "Days Secrets Manager keeps a deleted secret recoverable."
  default     = 30

  validation {
    condition     = var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30
    error_message = "The recovery window must be between 7 and 30 days; immediate deletion is not offered."
  }
}

variable "secret_value" {
  type        = string
  description = "Value to write through the write-only argument, or null to leave the value to a process outside Terraform."
  default     = null
  sensitive   = true
  ephemeral   = true

  validation {
    condition     = var.secret_value == null || try(length(var.secret_value) > 0, false)
    error_message = "The value, when given, must not be empty."
  }
}

variable "secret_value_version" {
  type        = number
  description = "Version of secret_value. 0 writes no value; raising it writes secret_value again."
  default     = 0

  validation {
    condition     = var.secret_value_version >= 0 && floor(var.secret_value_version) == var.secret_value_version
    error_message = "The version must be a whole number, 0 or greater."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the secret besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
