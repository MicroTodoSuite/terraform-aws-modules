# Plan-time tests of the iam-role module against a mocked AWS provider (PC-IAC-018).
mock_provider "aws" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "shd"
  role_name   = "lex-mts-shd-role-ecrpublish"
  description = "Publishes reviewed images to ECR."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" }
    }]
  })
  inline_policies = {
    "publish-images" = jsonencode({
      Version   = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = "ecr:PutImage", Resource = "*" }]
    })
  }
  managed_policy_arns      = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  permissions_boundary_arn = ""
}

run "creates_the_role_with_its_policies" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  assert {
    condition     = aws_iam_role.this.name == "lex-mts-shd-role-ecrpublish" && aws_iam_role.this.tags["Name"] == "lex-mts-shd-role-ecrpublish"
    error_message = "The role must carry the name the root built, also as its Name tag."
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600 && aws_iam_role.this.permissions_boundary == null
    error_message = "Sessions default to one hour, and an empty boundary means none."
  }

  assert {
    condition     = length(aws_iam_role_policy.this) == 1 && aws_iam_role_policy.this["publish-images"].name == "publish-images"
    error_message = "Each inline policy must become one role policy named by its key."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 1
    error_message = "Each managed policy must be attached once."
  }
}

run "applies_a_permissions_boundary_when_given" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    permissions_boundary_arn = "arn:aws:iam::123456789012:policy/lex-mts-shd-pol-boundary"
  }

  assert {
    condition     = aws_iam_role.this.permissions_boundary == "arn:aws:iam::123456789012:policy/lex-mts-shd-pol-boundary"
    error_message = "A given boundary must be applied."
  }
}

run "rejects_a_trust_policy_that_is_not_json" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    assume_role_policy = "not json"
  }

  expect_failures = [var.assume_role_policy]
}

run "rejects_a_boundary_that_is_not_a_policy_arn" {
  command = plan

  providers = {
    aws.project = aws.project
  }

  variables {
    permissions_boundary_arn = "boundary"
  }

  expect_failures = [var.permissions_boundary_arn]
}
