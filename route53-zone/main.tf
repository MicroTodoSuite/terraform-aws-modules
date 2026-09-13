# A public Route 53 hosted zone, protected from destruction (PC-IAC-010). Records are managed by the roots that own them.
resource "aws_route53_zone" "this" {
  provider = aws.project

  name          = var.zone_name
  comment       = var.comment
  force_destroy = false
  tags          = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
