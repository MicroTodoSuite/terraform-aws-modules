# A security group whose rules are separate resources, one source or destination each, as
# the provider documentation recommends; in-line rules are never used, so the two styles
# cannot overwrite each other. This module owns the security-group types (iac-contracts.json).
resource "aws_security_group" "this" {
  provider = aws.project

  name        = var.security_group_name
  description = var.description
  vpc_id      = var.vpc_id
  tags        = local.group_tags
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.ingress_rules
  provider = aws.project

  security_group_id            = aws_security_group.this.id
  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? aws_security_group.this.id : each.value.referenced_security_group_id
  tags                         = local.rule_tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.egress_rules
  provider = aws.project

  security_group_id            = aws_security_group.this.id
  description                  = each.value.description
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.self ? aws_security_group.this.id : each.value.referenced_security_group_id
  tags                         = local.rule_tags
}
