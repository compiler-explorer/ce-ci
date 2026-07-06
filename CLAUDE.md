# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository manages Compiler Explorer's CI infrastructure using AWS-hosted GitHub Actions runners. It uses the [terraform-aws-github-runner](https://github.com/github-aws-runners/terraform-aws-github-runner) module to provision on-demand, auto-scaling EC2 runners that scale to zero when idle.

## Key Architecture

### Multi-Runner System

The infrastructure supports multiple runner types defined in `templates/runner-configs/*.yaml`:

- linux-arm64 ARM64 Linux runners
- linux-x64-builder Linux x64 library builders
- linux-x64 Standard Linux x64 runners
- windows-x64-win-builder Windows builders

Each config specifies label matchers, AMI filters, instance types, scaling rules, and maximum runner count.

### Infrastructure Components

#### Terraform Structure

- `main.tf`: Core multi-runner module configuration
- `lambdas-download/`: Downloads Lambda functions from terraform-aws-github-runner releases
- `providers.tf`, `variables.tf`, `secrets.tf`: Standard Terraform configuration
- `outputs.tf`: Exports webhook URL and secret (sensitive)

#### Packer Images

Three different Packer configurations build AMIs:

- `packer/gha.pkr.hcl`: Standard Linux runners (x64/arm64)
- `packer/gha-lin-builder.pkr.hcl`: Linux x64 library builder configuration
- `packer/gha-win-builder.pkr.hcl`: Windows builder configuration

All images:

- Start from Ubuntu 22.04 Jammy (Linux) or Windows base
- Install Docker, AWS CLI, CloudWatch agent
- Clone and run setup from [CE infra repo](https://github.com/compiler-explorer/infra)
- Install GitHub Actions runner software at `/opt/actions-runner`

#### Packer Variables

- `packer-vars.hcl`: x64 Linux config (used by both standard and library builder)
- `packer-vars-arm64.hcl`: ARM64 Linux config
- `packer-vars-win-builder.hcl`: Windows builder config

## Common Commands

### Initial Deployment

1. Download Lambda functions:

   ```bash
   cd lambdas-download
   terraform init
   terraform apply
   cd ..
   ```

2. Deploy infrastructure:

   ```bash
   terraform init
   terraform apply
   ```

3. Configure GitHub App webhook (manual step):
   - Output sensitive values: `terraform output webhook`
   - Update at: https://github.com/organizations/compiler-explorer/settings/apps/compiler-explorer-ci

### Building AMIs

Build images for each architecture:

```bash
./build-image.sh              # x64 Linux standard runners
./build-image-arm64.sh        # ARM64 Linux runners
./build-image-lin-builder.sh  # Linux x64 library builder runners
./build-image-win-builder.sh  # Windows builder runners
```

Each script:

1. Runs `packer init` with the appropriate var file
2. Validates the Packer configuration
3. Builds and tags the AMI

After building new AMIs, run `terraform apply` to update the infrastructure.

### Updating Dependencies

See instructions in README.md

## Testing changes after a `terraform apply`

There is no PR/plan-review gate that proves runners actually work — the workflow
is: `terraform apply`, then trigger real GitHub Actions workflows to exercise the
change. Runner instances are ephemeral and per-job, so config changes only take
effect on the *next* runner launched of each type; nothing running is disturbed.

The [`infra`](https://github.com/compiler-explorer/infra) repo has
`workflow_dispatch` workflows (gated to `mattgodbolt`/`partouf`) that are the
handiest probes. Dispatch with `gh`, watch with `gh run watch <id> --repo
compiler-explorer/infra --exit-status`:

- **Any runner, arbitrary command** — `adhoc-command.yml` (input `size=small|
  medium|large`) and `adhoc-command-lin-builder.yml`. Run a shell command on the
  target tier. Ideal for quick checks like IMDSv2 or SSM.
- **Real Linux library build** — `lin-lib-build.yaml` with a *single* small
  library + *single* compiler (e.g. `library=fmt`, `compiler=g151`) instead of
  `all`/`popular-compilers-only`, to prove the builder AMI's toolchain end to end.
- **Real Windows library build** — `win-lib-build.yaml`, e.g. `library=fmt`,
  `compiler=vcpp_v19_51_VS18_6_x64`. Windows boots slowly (~7 min; note the
  `runner_boot_time_in_minutes: 20`), so allow time. Use the compiler-explorer
  MCP (`list_compilers`) to find valid compiler ids.

Useful checks:
- **IMDSv2**: on a runner, `aws sts get-caller-identity` must succeed (SDK path),
  a tokenless `curl http://169.254.169.254/latest/meta-data/...` must return
  `401`, and a tokened GET must return `200`.
- **What actually launched**: `aws ec2 describe-instances --region us-east-1
  --filters "Name=tag:ghr:environment,Values=ce-ci-<tier>"` shows instance type
  and lifecycle (spot/on-demand) — e.g. to confirm new instance types are in play.
- **Why scale-up did something**: the scale-up Lambda logs
  (`/aws/lambda/ce-ci-<tier>-scale-up`) explain launch decisions.
- Always confirm a follow-up `terraform plan` reports no drift.

## Important Details

### AMI Housekeeper

The `ami_housekeeper` Lambda automatically cleans up old AMIs tagged with `Subsystem=CI`. It runs based on the configuration in `main.tf` and is currently enabled with `dryRun = false`.

### Runner Naming & Tags

- All resources tagged with `Site=CompilerExplorer` and `Subsystem=CI`
- Runner prefixes and AMI naming patterns configured per runner type in YAML configs

### Network Configuration

Runners deploy to:

- VPC: `vpc-17209172`
- Subnets: Multiple across availability zones (us-east-1)
- Region: `us-east-1`

### Secrets Management

GitHub App credentials stored in AWS Secrets Manager, referenced in `main.tf` via `data.aws_secretsmanager_secret_version.ce_ci`.
