locals {
  environment = "ce-ci"
  aws_region  = "us-east-1"

  # Load runner configurations from Yaml files
  multi_runner_config = { for c in fileset("${path.module}/templates/runner-configs", "*.yaml") : trimsuffix(c, ".yaml") => yamldecode(file("${path.module}/templates/runner-configs/${c}")) }
}

resource "random_password" "random" {
  length = 28
}

resource "random_id" "random" {
  byte_length = 20
}

module "multi-runner" {
  source                            = "./terraform-aws-github-runner/modules/multi-runner"
  multi_runner_config               = local.multi_runner_config
  aws_region                        = local.aws_region
  vpc_id     = "vpc-17209172"
  subnet_ids = [
    "subnet-690ed81e",
    "subnet-1bed1d42",
    "subnet-1df1e135",
    "subnet-0b7ecd0395d5f2cc9",
    "subnet-00fe4d85550ee828d"
  ]
  runners_scale_up_lambda_timeout   = 60
  runners_scale_down_lambda_timeout = 60
  prefix = local.environment
  tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
  }
  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    webhook_secret = random_password.random.result
  }

  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"
}
