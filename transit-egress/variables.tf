# Inputs of the transit-egress module. Names arrive built by the root (PC-IAC-025); the egress
# VPC, its subnets, and its route tables come from the network module.
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
  description = "Environment code, from MTS-IAC-101. The hub is shared, so it is normally shd."

  validation {
    condition     = contains(["shd", "eco", "fdev", "fstg", "fprd"], var.environment)
    error_message = "The environment must be one of shd, eco, fdev, fstg, or fprd."
  }
}

variable "transit_gateway_name" {
  type        = string
  description = "Standard name of the transit gateway, such as lex-mts-shd-tgw-egress."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.transit_gateway_name)) && length(var.transit_gateway_name) <= 28
    error_message = "The transit gateway name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }
}

variable "hub_attachment_name" {
  type        = string
  description = "Standard name of the egress VPC's attachment, such as lex-mts-shd-tgwa-egress."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.hub_attachment_name)) && length(var.hub_attachment_name) <= 28
    error_message = "The attachment name must be a standard name of at most 28 characters."
  }
}

variable "hub_route_table_name" {
  type        = string
  description = "Standard name of the hub-side transit gateway route table, where each spoke installs its own return route."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.hub_route_table_name)) && length(var.hub_route_table_name) <= 28
    error_message = "The hub route table name must be a standard name of at most 28 characters."
  }
}

variable "hub_vpc" {
  type = object({
    id                    = string
    cidr_block            = string
    attachment_subnet_ids = list(string)
    public_route_table_id = string
  })
  description = "The egress VPC, built with the network module: its ID and CIDR, the private subnets that hold the attachment's network interfaces (one per zone, with nat egress), and the public route table of the NAT gateway's subnet."

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.hub_vpc.id)) && can(cidrhost(var.hub_vpc.cidr_block, 0)) && can(regex("^rtb-[0-9a-f]+$", var.hub_vpc.public_route_table_id))
    error_message = "The hub VPC needs a VPC ID, a valid IPv4 CIDR block, and a route table ID."
  }

  validation {
    condition     = length(var.hub_vpc.attachment_subnet_ids) > 0 && alltrue([for id in var.hub_vpc.attachment_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "The hub attachment needs at least one private subnet ID."
  }
}

variable "spokes" {
  type = map(object({
    vpc_cidr         = string
    route_table_name = string
  }))
  description = "Environments allowed to use the hub, keyed by a short spoke key such as fdev: each spoke's VPC CIDR and the standard name of its dedicated transit gateway route table. The hub creates that empty table and a return route in its public route table; the spoke's own state attaches its VPC, associates the attachment with its table, and installs its routes. {} for a hub with no spokes yet."

  validation {
    condition = alltrue([
      for key, spoke in var.spokes :
      can(regex("^[a-z][a-z0-9]{1,9}$", key)) && can(cidrhost(spoke.vpc_cidr, 0)) &&
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", spoke.route_table_name)) && length(spoke.route_table_name) <= 28
    ])
    error_message = "Every spoke needs a key of 2 to 10 lowercase letters or digits, a valid IPv4 CIDR block, and a standard route table name of at most 28 characters."
  }

  # Overlapping spokes cannot be routed from the hub: the more specific prefix wins and
  # the other spoke's return traffic disappears into it.
  validation {
    condition = alltrue(flatten([
      for a_key, a in var.spokes : [
        for b_key, b in var.spokes :
        a_key == b_key || !try(
          tonumber(split("/", a.vpc_cidr)[1]) <= tonumber(split("/", b.vpc_cidr)[1])
          ? cidrhost("${split("/", b.vpc_cidr)[0]}/${split("/", a.vpc_cidr)[1]}", 0) == cidrhost(a.vpc_cidr, 0)
          : cidrhost("${split("/", a.vpc_cidr)[0]}/${split("/", b.vpc_cidr)[1]}", 0) == cidrhost(b.vpc_cidr, 0),
          false
        )
      ]
    ]))
    error_message = "Two spokes have overlapping VPC CIDR blocks, which the hub cannot route apart."
  }

  # A spoke overlapping the egress VPC would be shadowed by the hub's local route.
  validation {
    condition = alltrue([
      for spoke in values(var.spokes) : !try(
        tonumber(split("/", var.hub_vpc.cidr_block)[1]) <= tonumber(split("/", spoke.vpc_cidr)[1])
        ? cidrhost("${split("/", spoke.vpc_cidr)[0]}/${split("/", var.hub_vpc.cidr_block)[1]}", 0) == cidrhost(var.hub_vpc.cidr_block, 0)
        : cidrhost("${split("/", var.hub_vpc.cidr_block)[0]}/${split("/", spoke.vpc_cidr)[1]}", 0) == cidrhost(spoke.vpc_cidr, 0),
        false
      )
    ])
    error_message = "A spoke VPC CIDR block overlaps the egress VPC, whose local route would shadow the spoke's return route."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to every resource besides Name and the provider's default tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty, and Name is set by the module."
  }
}
