# Compiler Explorer's CI infrastructure

Used to build our compilers, both ad hoc and on a regular basis.
Uses https://github.com/philips-labs/terraform-aws-github-runner to script
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
- Then `./build-image.sh` and `./build-image-arm64.sh`.
- Once built you'll need to rerun the `terraform apply`.

## To update the version of the philips code

- update the version in `lambdas-download/main.tf`
- `terraform apply` in `lambdas-download`
- update the version in `main.tf`
- `terraform init` in toplevel and `terraform apply`
