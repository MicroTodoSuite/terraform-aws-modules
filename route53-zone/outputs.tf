# Outputs of the route53-zone module.
output "zone_id" {
  description = "ID of the hosted zone, for records."
  value       = aws_route53_zone.this.zone_id
}

output "zone_arn" {
  description = "ARN of the hosted zone."
  value       = aws_route53_zone.this.arn
}

output "zone_name" {
  description = "Domain the hosted zone serves."
  value       = aws_route53_zone.this.name
}

output "name_server_names" {
  description = "Name servers to delegate the domain to at the registrar."
  value       = aws_route53_zone.this.name_servers
}
