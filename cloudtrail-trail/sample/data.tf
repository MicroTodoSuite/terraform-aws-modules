# Lookups by standard name. The sample reads only the partition of the recorded bucket's ARN.
data "aws_partition" "current" {
  provider = aws.principal
}
