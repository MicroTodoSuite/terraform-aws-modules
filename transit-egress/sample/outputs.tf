# Outputs that prove the sample works.
output "transit_gateway_id" {
  description = "ID of the sample transit gateway."
  value       = module.transit_egress.transit_gateway_id
}

output "spoke_route_table_ids" {
  description = "ID of each sample spoke's route table."
  value       = module.transit_egress.spoke_route_table_ids
}
