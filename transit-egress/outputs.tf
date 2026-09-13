# Outputs of the transit-egress module, consumed by each spoke's networking root.
output "transit_gateway_id" {
  description = "ID of the transit gateway a spoke attaches to."
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "ARN of the transit gateway, for sharing it and for scoping a spoke's permissions to this hub."
  value       = aws_ec2_transit_gateway.this.arn
}

output "hub_attachment_id" {
  description = "ID of the egress VPC's attachment; a spoke points its default transit gateway route at it."
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}

output "hub_route_table_id" {
  description = "ID of the hub-side transit gateway route table, where a spoke installs its return route."
  value       = aws_ec2_transit_gateway_route_table.hub.id
}

output "spoke_route_table_ids" {
  description = "ID of each spoke's dedicated transit gateway route table, keyed like var.spokes."
  value       = { for key, table in aws_ec2_transit_gateway_route_table.spoke : key => table.id }
}
