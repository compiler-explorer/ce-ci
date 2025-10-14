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
- update the version in `lambdas-download/main.tf`
- `terraform apply` in `lambdas-download`
- update the version in `main.tf`
- `terraform init` in toplevel and `terraform apply`. I recommend you `terraform plan` and review that, then apply the plan after it looks good.

## To update the GH Actions Runner version

- update the `runner_version` in:
  - `packer-vars.hcl` (x64 standard Linux and x64 library builder)
  - `packer-vars-arm64.hcl` (ARM64 Linux)
  - `packer-vars-win-builder.hcl` (Windows builder)
- update the packer images (see above)
