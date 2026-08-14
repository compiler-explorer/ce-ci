# Compiler Explorer's CI infrastructure

Used to build our compilers, both ad hoc and on a regular basis.
Uses https://github.com/github-aws-runners/terraform-aws-github-runner to script
up some custom GH Actions runners that run on our infrastructure on demand, and
scale back to zero when they're done. Our runners have access to the CE environment
and they are mostly set up by [the infra repo](https://github.com/compiler-explorer/infra/blob/main/setup-ci.sh).

## To deploy:

### Fetch the lambdas

- `cd lambdas-download`
- `terraform init`
- `terraform apply`
- `cd ..`

### Do the needful

- `terraform init`
- `terraform apply`

The webhook and secret should be the same every time,
but they go in https://github.com/organizations/compiler-explorer/settings/apps/compiler-explorer-ci.
If you need to output them you need to specifically ask them to be output
as they are sensitive secret values, shared with GitHub only:

```sh
$ terraform output webhook
```

## To update the packer image

- Make any changes in the `./packer` directory, as needed.
- Then run the appropriate build scripts:
  - `./build-image.sh` (x64 standard Linux runners)
  - `./build-image-arm64.sh` (ARM64 Linux runners)
  - `./build-image-lin-builder.sh` (Linux x64 library builder runners)
  - `./build-image-win-builder.sh` (Windows builder runners)
- Once built you'll need to rerun the `terraform apply`. I recommend you `terraform plan` and review that, then apply the plan after it looks good.

## To update the version of the github-aws-runners code

- Find the package in https://github.com/github-aws-runners/terraform-aws-github-runner/releases
  - check for any incompatibilities compared to the current version
- update the version in **all three** places: `lambdas-download/main.tf`
  (`local.version`), `main.tf` (the `multi-runner` module `version`), and
  `lambda-zips.tf` (`local.lambda_version`)
- `terraform apply` in `lambdas-download`. This is what actually downloads the
  new zips, and it is the step everyone forgets
- `terraform init` in toplevel and `terraform apply`. I recommend you `terraform plan` and review that, then apply the plan after it looks good.

### The lambda zips are checked at plan time

The four lambda zips are not in git; `lambdas-download/` curls them from the
upstream release, and terraform deploys whatever is on disk. Bumping the pinned
version does *not* refresh them, so skipping the `lambdas-download` apply
silently redeploys ancient lambda code alongside new configuration, which is
exactly what happened, undetected, until 2026-08-14.

`lambda-zips.tf` therefore compares the zips on disk against the digests GitHub
publishes for the pinned tag, and `terraform plan` warns if they differ:

```
│ Warning: Check block assertion failed
│ These lambda zips in lambdas-download/ are not the ones published for v7.9.0:
│ runners, webhook
```

It is a `check` block, so it warns rather than blocking the plan. If GitHub is
unreachable or rate-limiting (the call is unauthenticated, 60/hour), you instead
get "Could not verify the lambda zips: GitHub returned HTTP ..." and no
verification happens. That warning is worth reading, not ignoring.

## To update the GH Actions Runner version

- update the `runner_version` in:
  - `packer-vars.hcl` (x64 standard Linux and x64 library builder)
  - `packer-vars-arm64.hcl` (ARM64 Linux)
  - `packer-vars-win-builder.hcl` (Windows builder)
- update the packer images (see above)

## Keep the runner version and AMIs fresh, or jobs can get stuck

The `runner_version` pinned above is baked into the AMIs. If it falls behind
the current [actions/runner release](https://github.com/actions/runner/releases),
GitHub forces every freshly-booted runner to self-update and restart before it
will take jobs. That restart races against GitHub's job delivery, and can
permanently wedge a job (seen for real on 2026-07-09):

- the queued job gets internally pinned to the runner that restarted mid-delivery,
  and GitHub never offers it to any runner again — not even an idle one with
  matching labels;
- the idle runner is then reaped by the scale-down lambda (it runs every minute;
  runners are eligible after `minimum_running_time_in_minutes`, default 5);
- scale-up is purely webhook-driven and the job's one `queued` event was already
  consumed, so nothing ever launches again. The job sits "Queued" forever.

**To unstick a wedged job**: cancel and re-run the workflow — the re-run creates
a fresh job and a fresh webhook event:

```sh
gh run cancel <run-id> --repo compiler-explorer/<repo>
gh run rerun <run-id> --repo compiler-explorer/<repo>
```

**To prevent it**: bump `runner_version` and rebuild the AMIs whenever runners
start self-updating on boot (check `/github-self-hosted-runners/ce-ci-*/syslog`
in CloudWatch for "Downloading X.Y.Z runner" lines, or just rebuild every month
or two).

### job_retry: worth enabling, especially for ephemeral runners

The module has an (experimental) `runner_config.job_retry` option: after each
scale-up it queues a delayed re-check, and if the job is still queued it
re-publishes the scale-up event, launching another runner. Reading the v7.9.0
lambda source, it is *not* gated on ephemeral runners despite the docs' framing —
it works for our non-ephemeral config too. Defaults: `delay_in_seconds = 300`,
`delay_backoff = 2`, `max_attempts = 1`. Caveats: it costs extra GitHub App API
calls, and it would not have cured the 2026-07-09 wedge (GitHub refused to hand
that job to *any* runner; only cancel + re-run cleared it). It becomes much more
attractive when we move to ephemeral runners, where a lost webhook or runner
otherwise strands the job as a matter of course.
