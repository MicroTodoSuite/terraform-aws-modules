## Overview
This repository holds the reusable Terraform modules for AWS that the MicroTodoSuite live repositories consume by tag.
Each top-level directory is one single-responsibility module, versioned and released on its own; the repository contains no live root, no backend, and no state.

## Stack
- Infrastructure: Terraform HCL with the `hashicorp/aws` provider; the Terraform version is in `.terraform-version`.
- Tests: `terraform test` against mocked providers, one or more `tests/*.tftest.hcl` per module.
- Release tooling: release-please in manifest mode, one component per module.

## Commands
- Test a module: `terraform -chdir=<module> init -backend=false` then `terraform -chdir=<module> test`.
- Validate a module's example: `terraform -chdir=<module>/sample init -backend=false` then `terraform -chdir=<module>/sample validate`.
- Do not run `terraform validate` in a module directory: Terraform 1.15 rejects it for a module that declares `configuration_aliases`; `terraform test` validates the module instead.
- Run the rule contracts: `python3 <.github checkout>/scripts/iac/contracts.py repo . --kind modules`.

## Structure
- `<module>/`: one module in the PC-IAC-001 layout, with `sample/`, `tests/`, `README.md`, and `CHANGELOG.md`.
- `_template/`: the layout a new module is copied from; the checks skip it.
- `iac-contracts.json`: which modules own resource types that PC-IAC-023 forbids elsewhere, and which resources must carry `prevent_destroy`.
- `docs/iac-exceptions.md`: waived findings, each with a reason and an expiry.

## Conventions
- Follow `microservice-app-ai-agents/rules/iac/`: a module configures no provider and uses `provider = aws.project` on every resource; it receives names built by the root and never assembles them from `client`, `project`, or `environment`; it looks nothing up except the computational data sources PC-IAC-011 allows; it creates only the resources intrinsic to its one service.
- A commit touches one module and uses its name as scope: `feat(network): ...`. Tags are `<module>-vX.Y.Z` and come from release-please; never create a tag by hand.
- Write everything in English — branch names, commit messages, pull-request titles and bodies, review comments, code comments, documentation, and specification text. No bilingual sections. Changing this rule takes a recorded decision in `microservice-app-docs`, not a remark in conversation.
- Open every pull request through `.github/pull_request_template.md` and follow `microservice-app-docs/docs/Pull request and task tracking conventions.md`: one concern per short-lived `<type>/<summary>` branch, a Conventional Commit title with a scope, and every template section filled.
- Keep the Spec-Driven Development commit pair intact: `test(<module>): specify ...` must be committed failing before `feat(<module>): implement ...`, and the pull request merges with a merge commit so both stay on `main`.
- Track every task in the register named by the pull request, and tick it only against a located artifact.
- Before changing module code, the documentation MCP servers in `.mcp.json` MUST be connected and verified with `../microservice-app-ai-agents/scripts/check-mcp.sh terraform-aws .`; Codex users run `mcp/codex/setup-codex-mcp.sh terraform-aws` from that repository once. Every provider argument, version, service limit, and naming constraint is checked against them at the time of the change, never from memory, and the pull request lists what was consulted under "How it is verified". An agent that cannot reach them stops and reports.
- Never merge with `--admin`, force-push to `main`, disable a branch protection rule to land one's own work, or approve one's own pull request. An AI agent may open, describe, and update a pull request; it may never approve one and never author an acceptance or approval artifact — only a named human unlocks a gate.
- Report outcomes faithfully in commits and pull-request bodies: name what is red, say what was skipped, and correct an earlier claim that turns out to be wrong.

## Notes
- The repository name coincides with the public `terraform-aws-modules` organization on the Terraform Registry. Consumers therefore use the full Git URL with `?ref=<module>-vX.Y.Z`, never a registry address.
- A module never commits a lock file and declares only a minimum provider version (`>= 6.0.0`); the consuming root pins the exact provider.
