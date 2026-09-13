# Inputs of the eks-node-group sample.
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
  description = "Kubernetes minor version of the sample nodes."
}

variable "release_version" {
  type        = string
  description = "AMI release of the sample nodes."
}

variable "node_role_arn" {
  type        = string
  description = "Role the nodes assume; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets of the nodes; empty in terraform.tfvars, where they are looked up (PC-IAC-026)."
}
