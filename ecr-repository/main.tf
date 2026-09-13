# ECR repositories with immutable tags, scanning on push, and protection from destruction (PC-IAC-010).
resource "aws_ecr_repository" "this" {
  for_each = var.repositories
  provider = aws.project

  name                 = each.value.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.governance_tags, var.additional_tags, { Name = each.value.name, Service = each.key })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this
  provider = aws.project

  repository = each.value.name
  policy     = local.lifecycle_policy
}
