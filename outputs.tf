output "webhook" {
  sensitive = true
  value = {
    secret   = random_password.random.result
    endpoint = module.multi-runner.webhook.endpoint
  }
}
