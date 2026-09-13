# Inputs of the security-group sample.
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

variable "vpc_id" {
  type        = string
  description = "VPC of the sample group; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}
