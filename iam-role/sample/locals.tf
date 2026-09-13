# Name construction and policies for the iam-role sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  role_name = "${local.governance_prefix}-role-sample"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
