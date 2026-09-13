# Inputs of the ecr-repository module. Names arrive built by the root (PC-IAC-025).
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

variable "repositories" {
  type = map(object({
    name = string
  }))
  description = "Repositories keyed by service key; each name is the standard name the root built, such as lex-mts-shd-ecr-authapi."

  validation {
    condition     = length(var.repositories) > 0
    error_message = "At least one repository is required."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", repository.name)) && length(repository.name) <= 256
    ])
    error_message = "Repository names are lowercase letters and digits separated by single dots, hyphens, or underscores, with no path (MTS-IAC-101)."
  }
}

variable "untagged_image_expiry_days" {
  type        = number
  description = "Days after which an untagged image is expired."
  default     = 30

  validation {
    condition     = var.untagged_image_expiry_days >= 1 && var.untagged_image_expiry_days <= 365
    error_message = "The expiry must be between 1 and 365 days."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to every repository besides Name, Service, and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && !contains(["Name", "Service"], key)])
    error_message = "Tag keys must not be empty, and Name and Service are set by the module."
  }
}
