# Data sources: the account, partition, and Region the bucket name and the trail's ARN are
# built from, computational lookups PC-IAC-011 allows.
data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_partition" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}
