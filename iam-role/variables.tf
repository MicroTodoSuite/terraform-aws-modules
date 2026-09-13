# Inputs of the iam-role module. The trust and permission policies arrive as JSON built by the root.
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

variable "role_name" {
  type        = string
  description = "Standard name of the role, built by the root, such as lex-mts-shd-role-ecrpublish."

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "The role name must be 1 to 64 characters from the set IAM allows."
  }
}

variable "description" {
  type        = string
  description = "What the role is for, shown in IAM."

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 1000
    error_message = "The description must be 1 to 1000 characters."
  }
}

variable "assume_role_policy" {
  type        = string
  description = "Trust policy as JSON: who may assume the role and under which conditions."

  validation {
    condition     = can(jsondecode(var.assume_role_policy).Statement)
    error_message = "The trust policy must be a JSON policy document with a Statement."
  }
}

variable "inline_policies" {
  type        = map(string)
  description = "Inline permission policies as JSON, keyed by policy name."
  default     = {}

  validation {
    condition = alltrue([
      for name, policy in var.inline_policies :
      can(regex("^[A-Za-z0-9+=,.@_-]{1,128}$", name)) && can(jsondecode(policy).Statement)
    ])
    error_message = "Each inline policy needs a name IAM accepts and a JSON document with a Statement."
  }
}

variable "managed_policy_arns" {
  type        = set(string)
  description = "Managed policies to attach; an empty set attaches none."

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : startswith(arn, "arn:")])
    error_message = "Every managed policy must be given by ARN."
  }
}

variable "permissions_boundary_arn" {
  type        = string
  description = "ARN of the permissions boundary, or an empty string for none."

  validation {
    condition     = var.permissions_boundary_arn == "" || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:policy/", var.permissions_boundary_arn))
    error_message = "The boundary must be empty or an IAM policy ARN."
  }
}

variable "max_session_duration" {
  type        = number
  description = "Longest session, in seconds, a principal may request when it assumes the role."
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "The session duration must be between 3600 and 43200 seconds, as IAM allows."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the role besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
