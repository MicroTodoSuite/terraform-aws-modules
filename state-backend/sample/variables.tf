# Inputs of the state-backend sample.
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
