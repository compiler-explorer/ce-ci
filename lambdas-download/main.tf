locals {
  version = "v6.5.10"
}

module "lambdas" {
  source  = "github-aws-runners/github-runner/aws//modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = local.version
    },
    {
      name = "runners"
      tag  = local.version
    },
    {
      name = "runner-binaries-syncer"
      tag  = local.version
    },
    {
      name = "ami-housekeeper"
      tag  = local.version
    }
  ]
}

output "files" {
  value = module.lambdas.files
}
