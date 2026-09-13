# The security-group sample: one call of the module, fed from locals.
module "security_group" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client              = var.client
  project             = var.project
  environment         = var.environment
  security_group_name = local.security_group_name
  description         = "Sample group admitting HTTPS from private addresses."
  vpc_id              = var.vpc_id
  ingress_rules       = local.ingress_rules
  egress_rules        = local.egress_rules
}
