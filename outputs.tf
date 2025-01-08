output "runners" {
  value = {
    value = [for s in module.multi-runner.binaries_syncer : s.lambda.function_name]
  }
}

output "webhook" {
  sensitive = true
  value = {
    secret   = random_password.random.result
    endpoint = module.multi-runner.webhook.endpoint
  }
}
