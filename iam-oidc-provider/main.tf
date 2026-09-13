# An IAM OpenID Connect provider. No thumbprint is set: for GitHub and other providers AWS
# trusts, IAM validates the certificate against its own library of root CAs.
resource "aws_iam_openid_connect_provider" "this" {
  provider = aws.project

  url            = var.url
  client_id_list = var.client_ids
  tags           = local.tags
}
