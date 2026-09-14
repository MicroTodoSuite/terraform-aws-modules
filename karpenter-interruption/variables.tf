# Inputs of the Karpenter interruption module. The root builds every name (PC-IAC-025).
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

variable "queue" {
  type = object({
    name                      = string
    message_retention_seconds = number
    kms_key_arn               = string
  })
  description = "The interruption queue: the standard name the root built, how long Amazon SQS keeps a message, and the customer KMS key that encrypts it, or an empty string for SQS-owned encryption. Karpenter's reference template retains messages for 300 seconds, because an interruption is worthless once the instance is gone."

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,80}$", var.queue.name))
    error_message = "The queue name must be 1 to 80 letters, digits, underscores, or hyphens, as Amazon SQS requires."
  }

  validation {
    condition     = var.queue.message_retention_seconds >= 60 && var.queue.message_retention_seconds <= 1209600
    error_message = "The retention must be between 60 and 1209600 seconds."
  }

  validation {
    condition     = var.queue.kms_key_arn == "" || can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.queue.kms_key_arn))
    error_message = "The KMS key must be empty or a KMS key ARN."
  }
}

variable "rule_names" {
  type = object({
    scheduled_change      = string
    spot_interruption     = string
    rebalance             = string
    instance_state_change = string
    capacity_reservation  = string
  })
  description = "Standard name of each EventBridge rule, built by the root: the AWS Health scheduled change, the Spot interruption warning, the rebalance recommendation, the instance state change, and the capacity reservation interruption."

  validation {
    condition     = alltrue([for name in values(var.rule_names) : can(regex("^[A-Za-z0-9._-]{1,64}$", name))])
    error_message = "Every rule name must be 1 to 64 letters, digits, dots, underscores, or hyphens, as EventBridge requires."
  }

  validation {
    condition     = length(distinct(values(var.rule_names))) == length(values(var.rule_names))
    error_message = "Every rule needs its own name."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the queue and the rules besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0])
    error_message = "Tag keys must not be empty."
  }
}
