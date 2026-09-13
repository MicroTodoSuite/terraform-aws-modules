# Name construction and rules for the security-group sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  security_group_name = "${local.governance_prefix}-sg-sample"

  ingress_rules = {
    https = { description = "HTTPS from inside the VPC", ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "10.0.0.0/8" }
  }

  egress_rules = {
    https = { description = "HTTPS to inside the VPC", ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "10.0.0.0/8" }
  }
}
