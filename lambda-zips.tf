# The lambda zips are not in git: lambdas-download/ curls them and terraform deploys
# whatever is on disk, so bumping the pinned version does not refresh them. On
# 2026-08-14 we found the deployed lambdas were years older than the pinned version
# because that separate apply had been skipped, and nothing had noticed.
locals {
  # Keep in sync with the multi-runner module version in main.tf and with
  # lambdas-download/main.tf. A module version must be a literal, so it cannot be shared.
  lambda_version = "v7.9.0"

  lambda_zips = { for name in ["webhook", "runners", "runner-binaries-syncer", "ami-housekeeper"] :
  name => "lambdas-download/${name}.zip" }

  # Empty if the response is not the shape we expect, so an API change surfaces as a
  # mismatch rather than passing vacuously.
  lambda_published = try({
    for asset in jsondecode(data.http.lambda_release.response_body).assets :
    trimsuffix(asset.name, ".zip") => trimprefix(asset.digest, "sha256:")
  }, {})

  lambda_stale = [for name, path in local.lambda_zips : name
  if try(filesha256(path), "") != lookup(local.lambda_published, name, "")]
}

data "http" "lambda_release" {
  url = "https://api.github.com/repos/github-aws-runners/terraform-aws-github-runner/releases/tags/${local.lambda_version}"
}

# A check block warns rather than failing the plan, and the http provider does not error
# on non-2xx, so a rate-limited API cannot block an unrelated apply.
check "lambda_zips_match_pinned_version" {
  assert {
    condition     = data.http.lambda_release.status_code == 200
    error_message = "Could not verify the lambda zips: GitHub returned HTTP ${data.http.lambda_release.status_code} for ${local.lambda_version}."
  }

  assert {
    condition     = data.http.lambda_release.status_code != 200 || length(local.lambda_stale) == 0
    error_message = "Not the zips published for ${local.lambda_version} (${join(", ", local.lambda_stale)}): run `cd lambdas-download && terraform apply`."
  }
}
