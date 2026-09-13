# Outputs that prove the sample works.
output "name_server_names" {
  description = "Name servers of the sample zone."
  value       = module.route53_zone.name_server_names
}
