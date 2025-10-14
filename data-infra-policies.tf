# Look up IAM policies from infra by their stable names
# These policies are defined in repo compiler-explorer/infra in terraform/security.tf

data "aws_iam_policy" "update_library_build_history" {
  name = "UpdateLibraryBuildHistory"
}

data "aws_iam_policy" "access_ce_params" {
  name = "AccessCeParams"
}

data "aws_iam_policy" "read_s3_minimal" {
  name = "ReadS3Minimal"
}

locals {
  # Attached via runner_iam_role_managed_policy_arns in main.tf
  policies = [
    data.aws_iam_policy.update_library_build_history.arn,
    data.aws_iam_policy.access_ce_params.arn,
    data.aws_iam_policy.read_s3_minimal.arn,
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}
