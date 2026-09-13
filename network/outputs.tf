# Outputs of the network module, consumed by the security and workload roots.
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "ID of each public subnet, keyed like var.subnets."
  value       = { for key, subnet in aws_subnet.this : key => subnet.id if var.subnets[key].tier == "public" }
}

output "private_subnet_ids" {
  description = "ID of each private subnet, keyed like var.subnets."
  value       = { for key, subnet in aws_subnet.this : key => subnet.id if var.subnets[key].tier == "private" }
}

output "public_route_table_id" {
  description = "ID of the route table shared by the public subnets."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "ID of each private subnet's route table, keyed like var.subnets."
  value       = { for key, table in aws_route_table.private : key => table.id }
}

output "nat_gateway_ids" {
  description = "ID of each NAT gateway, keyed like var.nat_gateways."
  value       = { for key, nat in aws_nat_gateway.this : key => nat.id }
}

output "nat_eip_allocation_ids" {
  description = "Allocation ID of each NAT gateway's Elastic IP, keyed like var.nat_gateways."
  value       = { for key, eip in aws_eip.this : key => eip.allocation_id }
}

output "flow_log_id" {
  description = "ID of the VPC flow log."
  value       = aws_flow_log.this.id
}

output "flow_log_group_arn" {
  description = "ARN of the flow log's CloudWatch log group."
  value       = aws_cloudwatch_log_group.flow_log.arn
}
