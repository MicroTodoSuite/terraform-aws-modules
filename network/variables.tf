# Inputs of the network module. Every name arrives built by the root (PC-IAC-025).
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

variable "vpc" {
  type = object({
    name       = string
    cidr_block = string
  })
  description = "Standard name and IPv4 CIDR block of the VPC, such as lex-mts-eco-vpc-main and 10.10.0.0/16."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.vpc.name)) && length(var.vpc.name) <= 28
    error_message = "The VPC name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }

  validation {
    condition     = can(cidrhost(var.vpc.cidr_block, 0)) && tonumber(split("/", var.vpc.cidr_block)[1]) >= 16 && tonumber(split("/", var.vpc.cidr_block)[1]) <= 28
    error_message = "The VPC CIDR must be a valid IPv4 block between /16 and /28, the sizes AWS allows."
  }
}

variable "internet_gateway_name" {
  type        = string
  description = "Standard name of the internet gateway, such as lex-mts-eco-igw-main."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.internet_gateway_name)) && length(var.internet_gateway_name) <= 28
    error_message = "The internet gateway name must be a standard name of at most 28 characters."
  }
}

variable "public_route_table_name" {
  type        = string
  description = "Standard name of the route table shared by the public subnets, such as lex-mts-eco-rtb-public."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.public_route_table_name)) && length(var.public_route_table_name) <= 28
    error_message = "The public route table name must be a standard name of at most 28 characters."
  }
}

variable "subnets" {
  type = map(object({
    name              = string
    availability_zone = string
    cidr_block        = string
    tier              = string
    route_table_name  = optional(string)
    egress            = optional(string, "none")
    nat_gateway_key   = optional(string)
    tags              = optional(map(string), {})
  }))
  description = <<-EOT
    Subnets keyed by a short key such as puba or priva. A public subnet routes through the internet gateway.
    A private subnet gets its own route table (route_table_name) and default route per egress: "nat" through
    nat_gateways[nat_gateway_key], "transit" through transit_gateway_id, or "none". tags carries discovery tags
    such as kubernetes.io/role/elb.
  EOT

  validation {
    condition     = length(var.subnets) > 0 && alltrue([for subnet in values(var.subnets) : contains(["public", "private"], subnet.tier)])
    error_message = "At least one subnet is required, and every tier must be public or private."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", subnet.name)) && length(subnet.name) <= 28 && can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "Every subnet needs a standard name of at most 28 characters and a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.tier == "public" || (subnet.route_table_name != null && contains(["nat", "transit", "none"], subnet.egress))
    ])
    error_message = "A private subnet needs route_table_name and an egress of nat, transit, or none."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      subnet.egress != "nat" || (subnet.nat_gateway_key != null && contains(keys(var.nat_gateways), coalesce(subnet.nat_gateway_key, "-")))
    ])
    error_message = "A subnet with nat egress must name one of the nat_gateways keys."
  }

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : subnet.egress != "transit" || var.transit_gateway_id != ""])
    error_message = "A subnet with transit egress needs transit_gateway_id."
  }
}

variable "nat_gateways" {
  type = map(object({
    name       = string
    eip_name   = string
    subnet_key = string
  }))
  description = "NAT gateways keyed by a short key, each in the public subnet subnets[subnet_key] with its own Elastic IP. One entry for a single NAT, one per zone for zonal NATs, none for a transit spoke. A precondition on the gateway rejects a private subnet_key, because this variable and var.subnets cannot validate each other without a cycle."
  default     = {}

  validation {
    condition = alltrue([
      for nat in values(var.nat_gateways) :
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", nat.name)) && can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", nat.eip_name)) && length(nat.name) <= 28 && length(nat.eip_name) <= 28
    ])
    error_message = "Every NAT gateway and Elastic IP needs a standard name of at most 28 characters."
  }
}

variable "transit_gateway_id" {
  type        = string
  description = "Transit gateway that private subnets with transit egress route through, or an empty string when none do."

  validation {
    condition     = var.transit_gateway_id == "" || can(regex("^tgw-[0-9a-f]{8,17}$", var.transit_gateway_id))
    error_message = "The transit gateway ID must be empty or look like tgw-0123456789abcdef0."
  }
}

variable "transit_attachment" {
  type = object({
    name               = string
    subnet_keys        = list(string)
    route_table_id     = string
    hub_attachment_id  = string
    hub_route_table_id = string
  })
  description = "The spoke side of a transit-egress hub, or null for a VPC without transit egress: the attachment's standard name; the private subnets that hold its network interfaces, at most one per Availability Zone; this spoke's dedicated route table and the hub attachment, from transit-egress; and the hub route table that receives this VPC's return route."

  validation {
    condition     = var.transit_attachment == null || var.transit_gateway_id != ""
    error_message = "A transit attachment needs transit_gateway_id."
  }

  validation {
    condition = var.transit_attachment == null || try(
      can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.transit_attachment.name)) && length(var.transit_attachment.name) <= 28 &&
      can(regex("^tgw-rtb-[0-9a-f]+$", var.transit_attachment.route_table_id)) &&
      can(regex("^tgw-rtb-[0-9a-f]+$", var.transit_attachment.hub_route_table_id)) &&
      can(regex("^tgw-attach-[0-9a-f]+$", var.transit_attachment.hub_attachment_id)),
      false
    )
    error_message = "The attachment needs a standard name of at most 28 characters, transit gateway route table IDs, and a hub attachment ID."
  }

  validation {
    condition = var.transit_attachment == null || try(
      length(var.transit_attachment.subnet_keys) > 0 &&
      alltrue([for key in var.transit_attachment.subnet_keys : var.subnets[key].tier == "private"]) &&
      length(distinct([for key in var.transit_attachment.subnet_keys : var.subnets[key].availability_zone])) == length(var.transit_attachment.subnet_keys),
      false
    )
    error_message = "The attachment needs at least one private subnet key, and at most one subnet per Availability Zone, as a transit gateway attachment allows."
  }
}

variable "flow_log" {
  type = object({
    name                     = string
    log_group_name           = string
    log_group_standard_name  = string
    retention_in_days        = number
    kms_key_arn              = string
    iam_role_arn             = string
    traffic_type             = optional(string, "ALL")
    max_aggregation_interval = optional(number, 60)
  })
  description = <<-EOT
    VPC flow logs to an encrypted CloudWatch log group. name is the flow log's standard name; log_group_name is the
    group's path, such as /aws/vpc-flow-logs/lex-mts-eco-vpc-main, and log_group_standard_name its Name tag. The
    delivery role and the key come from the shared security root, which exists before any environment's network.
  EOT

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log.retention_in_days)
    error_message = "The retention must be one of the values CloudWatch Logs accepts; never-expire (0) is not offered."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:kms:", var.flow_log.kms_key_arn)) && can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/", var.flow_log.iam_role_arn))
    error_message = "The flow log needs a KMS key ARN and an IAM role ARN."
  }

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log.traffic_type) && contains([60, 600], var.flow_log.max_aggregation_interval)
    error_message = "traffic_type must be ALL, ACCEPT, or REJECT, and max_aggregation_interval 60 or 600 seconds."
  }

  validation {
    condition     = startswith(var.flow_log.log_group_name, "/aws/vpc-flow-logs/") && can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.flow_log.name)) && can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.flow_log.log_group_standard_name))
    error_message = "The log group lives under /aws/vpc-flow-logs/, and the flow log and log group need standard names."
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
