# Plan-time tests of the iam-oidc-provider module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client        = "lex"
  project       = "mts"
  environment   = "shd"
  url           = "https://token.actions.githubusercontent.com"
  client_ids    = ["sts.amazonaws.com"]
  standard_name = "lex-mts-shd-oidc-github"
}

run "creates_the_provider_for_the_issuer" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_iam_openid_connect_provider.this.url == "https://token.actions.githubusercontent.com"
    error_message = "The provider must trust exactly the given issuer."
  }

  assert {
    condition     = toset(aws_iam_openid_connect_provider.this.client_id_list) == toset(["sts.amazonaws.com"])
    error_message = "The provider must accept exactly the given audiences."
  }

  assert {
    condition     = aws_iam_openid_connect_provider.this.tags["Name"] == "lex-mts-shd-oidc-github"
    error_message = "The Name tag must follow the standard pattern (MTS-IAC-101)."
  }
}

run "rejects_an_issuer_without_https" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    url = "http://token.actions.githubusercontent.com"
  }

  expect_failures = [var.url]
}

run "rejects_an_empty_audience_list" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    client_ids = []
  }

  expect_failures = [var.client_ids]
}
