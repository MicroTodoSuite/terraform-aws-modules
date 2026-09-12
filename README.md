# terraform-aws-modules

Reusable Terraform modules for AWS. The MicroTodoSuite live repositories
consume them by tag. GaCode Solutions maintains them for the MicroTodoSuite
platform it operates for Lexfield Legal.

Each top-level directory is one module with a single responsibility, and each
module is versioned on its own (MTS-IAC-102). A change to one module never forces
a consumer of another to move.

## Consuming a module

Always use the full Git URL and an exact module tag. The repository name
coincides with the public `terraform-aws-modules` organization on the Terraform
Registry, so a registry address would resolve to someone else's module.

```hcl
module "network" {
  source = "git::https://github.com/MicroTodoSuite/terraform-aws-modules.git//network?ref=network-v1.0.0"

  providers = {
    aws.project = aws.principal
  }

  # Names arrive built by the root (PC-IAC-025); governance codes feed tags.
  client      = var.client
  project     = var.project
  environment = var.environment
}
```

Modules configure no provider. They receive `aws.project` from the consuming
root (PC-IAC-005).

## Versions and releases

- Tags have the form `<module>-v<MAJOR>.<MINOR>.<PATCH>`, for example
  `network-v1.2.0`.
- Commits that touch a module use the module's name as the Conventional Commit
  scope, for example `feat(network): ...`. A `BREAKING CHANGE` footer produces a
  major version. A commit touches one module only.
- release-please, in manifest mode, opens a release pull request per module
  from merged commits and keeps each module's `CHANGELOG.md`.

## Adding a module

Copy `_template/`, rename it, and fill every file. The template follows
PC-IAC-001: `versions.tf`, `providers.tf`, `variables.tf`, `locals.tf`,
`data.tf`, `main.tf`, `outputs.tf`, `README.md`, `CHANGELOG.md`, a runnable
`sample/`, and `tests/` with `terraform test` files against a mocked provider.

## Checks

Every pull request runs the organization's reusable `iac-checks` gate:
- the rule contracts;
- `terraform fmt`;
- `terraform test` for each module;
- `terraform validate` for each sample;
- tflint;
- Trivy, failing on HIGH and CRITICAL findings.

A finding is waived only by a row, with a reason and an expiry, in
`docs/iac-exceptions.md`. The rules are in `microservice-app-ai-agents/rules/iac/`.
