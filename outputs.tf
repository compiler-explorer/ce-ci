output "runners" {
  value = {
    lambda_syncer_name = module.runners.binaries_syncer.lambda.function_name
  }
}

output "webhook" {
  sensitive = false
  value = {
    secret   = nonsensitive(random_password.random.result)
    endpoint = module.runners.webhook.endpoint
  }
}
