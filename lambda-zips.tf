# The lambda zips the multi-runner module deploys are deliberately not in git:
# they are fetched from the upstream release by the *separate* root module in
# lambdas-download/, and terraform just hashes whatever happens to be on disk.
# Bumping the module version (here and in lambdas-download/main.tf) does not
# refresh them -- that needs the extra `cd lambdas-download && terraform apply`,
# which is easy to skip. On 2026-08-14 we found the deployed lambdas were years
# older than the pinned version because that step had been skipped, and every
# apply since had silently redeployed the ancient code. Nothing noticed.
#
# So: compare the zips on disk against the digests GitHub publishes for the
# pinned tag, and shout at plan time. This costs one unauthenticated request to
# api.github.com per plan (the limit is 60/hour, so it is not a practical
# concern). It cannot make a plan fail spuriously: the http provider does not
# error on a non-2xx response, so a rate-limited or unavailable API just leaves
# status_code != 200 and the check reports that it could not verify. A plan here
# already needs the network to reach the S3 backend, so requiring it is no new
# constraint.
locals {
  # Keep in sync with the multi-runner module `version` in main.tf, and with
  # `local.version` in lambdas-download/main.tf. Terraform requires a module
  # `version` to be a literal, so it cannot be shared as a variable.
  lambda_version = "v7.9.0"

  lambda_zips = {
    for name in ["webhook", "runners", "runner-binaries-syncer", "ami-housekeeper"] :
    name => "lambdas-download/${name}.zip"
  }

  lambda_digests_on_disk = {
    for name, path in local.lambda_zips : name => try(filesha256(path), "(not downloaded)")
  }

  # Empty if the response was not the JSON we expect, so that a change in the
  # release API shows up as a mismatch rather than passing vacuously.
  lambda_digests_published = try({
    for asset in jsondecode(data.http.lambda_release.response_body).assets :
    trimsuffix(asset.name, ".zip") => trimprefix(asset.digest, "sha256:")
    if contains(keys(local.lambda_zips), trimsuffix(asset.name, ".zip"))
  }, {})

  lambda_zips_mismatched = [
    for name, digest in local.lambda_digests_on_disk : name
    if digest != lookup(local.lambda_digests_published, name, "")
  ]
}

data "http" "lambda_release" {
  url             = "https://api.github.com/repos/github-aws-runners/terraform-aws-github-runner/releases/tags/${local.lambda_version}"
  request_headers = { Accept = "application/vnd.github+json" }
}

check "lambda_zips_match_pinned_version" {
  assert {
    condition     = data.http.lambda_release.status_code == 200
    error_message = "Could not verify the lambda zips: GitHub returned HTTP ${data.http.lambda_release.status_code} for the ${local.lambda_version} release (rate limited, or the tag does not exist)."
  }

  assert {
    condition     = data.http.lambda_release.status_code != 200 || length(local.lambda_zips_mismatched) == 0
    error_message = <<-EOT
      These lambda zips in lambdas-download/ are not the ones published for ${local.lambda_version}:
      ${join(", ", local.lambda_zips_mismatched)}

      They are missing, stale, or partially downloaded, and applying now would deploy
      that old lambda code alongside ${local.lambda_version} configuration. Refresh them with:

          cd lambdas-download && terraform apply
    EOT
  }
}
