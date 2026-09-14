# Inputs of the trail sample.
variable "client" {
  type        = string
  description = "Client code."
}

variable "project" {
  type        = string
  description = "Project code."
}

variable "environment" {
  type        = string
  description = "Environment code."
}

variable "region" {
  type        = string
  description = "AWS region of the sample."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of a customer KMS key whose policy lets the sample trail encrypt; see the module README."
}

variable "recorded_bucket_name" {
  type        = string
  description = "Full name of the bucket whose object-level events the sample trail records."
}
