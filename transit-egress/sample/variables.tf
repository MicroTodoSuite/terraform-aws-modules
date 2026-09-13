# Inputs of the transit-egress sample.
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

variable "hub_vpc_id" {
  type        = string
  description = "Egress VPC from a network call; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}

variable "hub_attachment_subnet_ids" {
  type        = list(string)
  description = "Private subnets of the egress VPC; empty in terraform.tfvars, where they are looked up (PC-IAC-026)."
}

variable "hub_public_route_table_id" {
  type        = string
  description = "Public route table of the egress VPC; empty in terraform.tfvars, where it is looked up (PC-IAC-026)."
}
