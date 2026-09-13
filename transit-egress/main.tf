# The centralized-egress hub: a transit gateway that isolates its spokes, the egress VPC's
# attachment and route table, one empty route table per spoke, and the return routes the
# NAT gateway's subnet needs. The egress VPC itself is a network module call.
#
# Both defaults are disabled: with default association a new attachment would join one
# shared table, and with default propagation its CIDR would reach every attachment already
# there, which is how a spoke silently becomes reachable from its neighbours.
resource "aws_ec2_transit_gateway" "this" {
  provider = aws.project

  description                     = "Centralized egress hub; spokes reach the internet through it and never each other."
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "disable"
  tags                            = merge(local.base_tags, { Name = var.transit_gateway_name })
}

# The only attachment the hub owns. Each spoke attaches itself from its own state.
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  provider = aws.project

  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = var.hub_vpc.id
  subnet_ids                                      = var.hub_vpc.attachment_subnet_ids
  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = merge(local.base_tags, { Name = var.hub_attachment_name })
}

# Spokes install their return routes here, which is why the hub leaves it empty.
resource "aws_ec2_transit_gateway_route_table" "hub" {
  provider = aws.project

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = merge(local.base_tags, { Name = var.hub_route_table_name })
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  provider = aws.project

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# One dedicated table per spoke, empty on purpose. A spoke associates its attachment with
# its own table and adds one default route to the hub; no table ever holds a route toward
# another spoke, so spoke-to-spoke traffic has nowhere to go.
resource "aws_ec2_transit_gateway_route_table" "spoke" {
  for_each = var.spokes
  provider = aws.project

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = merge(local.base_tags, { Name = each.value.route_table_name, Spoke = each.key })
}

# The NAT gateway translates a reply back to the spoke's private address, which the public
# route table otherwise does not know; without this route the spoke's connections hang on
# the reply. The route names the transit gateway, never a spoke attachment, so it opens no
# path between spokes.
resource "aws_route" "spoke_return" {
  for_each = var.spokes
  provider = aws.project

  route_table_id         = var.hub_vpc.public_route_table_id
  destination_cidr_block = each.value.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id

  # Traffic can use the route only once the egress VPC is attached; no attribute here
  # refers to the attachment.
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hub]
}
