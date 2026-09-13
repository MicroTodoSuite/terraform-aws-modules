# The ecr-repository sample: one call of the module, fed from locals.
module "ecr_repository" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client       = var.client
  project      = var.project
  environment  = var.environment
  repositories = local.repositories
}
