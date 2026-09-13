# Data sources of the state-backend module: the account that owns the bucket, a computational lookup PC-IAC-011 allows.
data "aws_caller_identity" "current" {
  provider = aws.project
}
