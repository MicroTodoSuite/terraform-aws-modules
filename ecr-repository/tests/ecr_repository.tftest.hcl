# Plan-time tests of the ecr-repository module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "shd"
  repositories = {
    authapi  = { name = "lex-mts-shd-ecr-authapi" }
    todosapi = { name = "lex-mts-shd-ecr-todosapi" }
  }
}

run "creates_immutable_scanned_repositories" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = length(aws_ecr_repository.this) == 2 && aws_ecr_repository.this["authapi"].name == "lex-mts-shd-ecr-authapi"
    error_message = "One repository per entry, named as the root built it."
  }

  assert {
    condition = alltrue([
      for repository in aws_ecr_repository.this :
      repository.image_tag_mutability == "IMMUTABLE" && one(repository.image_scanning_configuration).scan_on_push && !repository.force_delete
    ])
    error_message = "Every repository must have immutable tags, scan on push, and refuse deletion while it holds images."
  }

  assert {
    condition     = aws_ecr_repository.this["authapi"].tags["Name"] == "lex-mts-shd-ecr-authapi" && aws_ecr_repository.this["authapi"].tags["Service"] == "authapi"
    error_message = "The Name tag must equal the name, and the Service tag the key."
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.this["authapi"].policy).rules[0].selection.countNumber == 30
    error_message = "Untagged images must expire after 30 days by default."
  }
}

run "rejects_a_repository_name_with_a_path" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    repositories = {
      authapi = { name = "microtodosuite/authapi" }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_an_empty_set_of_repositories" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    repositories = {}
  }

  expect_failures = [var.repositories]
}
