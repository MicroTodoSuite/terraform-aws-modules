# Inputs of the eks-cluster sample.
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

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes minor version of the sample cluster."
}

variable "cluster_role_arn" {
  type        = string
  description = "Role the control plane assumes; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets in two zones; empty in terraform.tfvars, where they are looked up (PC-IAC-026)."
}

variable "secrets_kms_key_arn" {
  type        = string
  description = "Key for Kubernetes secrets; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "log_kms_key_arn" {
  type        = string
  description = "Key for the control-plane log group; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}
