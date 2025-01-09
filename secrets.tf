data "aws_secretsmanager_secret" "ce_ci" {
  name = "ce_ci"
}

data "aws_secretsmanager_secret_version" "ce_ci" {
  secret_id = data.aws_secretsmanager_secret.ce_ci.id
}
