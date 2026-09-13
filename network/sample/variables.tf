# Inputs of the network sample.
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

variable "flow_log_kms_key_arn" {
  type        = string
  description = "Key for the flow-log group; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "flow_log_role_arn" {
  type        = string
  description = "Role that delivers flow logs; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}
