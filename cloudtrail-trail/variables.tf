# Inputs of the CloudTrail trail module. The root builds every name (PC-IAC-025).
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

variable "trail_name" {
  type        = string
  description = "Standard name of the trail, such as lex-mts-shd-ct-tfstate."

  validation {
    condition = (
      length(var.trail_name) >= 3 && length(var.trail_name) <= 128
      && can(regex("^[A-Za-z0-9][A-Za-z0-9._-]*[A-Za-z0-9]$", var.trail_name))
      && !can(regex("[._-]{2}", var.trail_name))
      && !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.trail_name))
    )
    error_message = "The trail name must be 3 to 128 letters, digits, periods, underscores, or hyphens, start and end with a letter or digit, hold no two separators together, and not look like an IP address, as CloudTrail requires."
  }
}

variable "bucket_name" {
  type        = string
  description = "Standard name of the log bucket, such as lex-mts-shd-s3-cloudtrail. The module appends the account ID, which keeps the global name unique."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$", var.bucket_name))
    error_message = "The bucket name must be 3 to 50 lowercase letters, digits, or hyphens, leaving room for the account suffix within the 63 characters S3 allows."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the customer KMS key that encrypts the log files, the digest files, and the bucket. Its policy must let this trail generate data keys and describe the key; see the README."

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "The key must be a KMS key ARN."
  }
}

variable "s3_object_arn_prefixes" {
  type        = list(string)
  description = "Object ARN prefixes whose S3 data events the trail records: a bucket ARN, a slash, and an optional key prefix, such as arn:aws:s3:::lex-mts-shd-s3-tfstate-123456789012/."

  validation {
    condition     = length(var.s3_object_arn_prefixes) > 0 && alltrue([for arn in var.s3_object_arn_prefixes : can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]/", arn))])
    error_message = "Name at least one object ARN prefix, each a bucket ARN followed by a slash; without the slash the trail would also record every bucket whose name begins the same way."
  }
}

variable "log_retention" {
  type = object({
    current_days    = number
    noncurrent_days = number
  })
  description = "How many days Amazon S3 keeps each log and digest file before expiring it, and how many days it keeps a version once it is no longer current."

  validation {
    condition     = var.log_retention.current_days >= 1 && var.log_retention.noncurrent_days >= 1 && floor(var.log_retention.current_days) == var.log_retention.current_days && floor(var.log_retention.noncurrent_days) == var.log_retention.noncurrent_days
    error_message = "Both retentions must be whole numbers of days, at least one."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the trail and the bucket besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
