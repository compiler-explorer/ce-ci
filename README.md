Extremely poor hack at CI infrastructure.

PRIVATE repo as it has keys in it.

## To deploy:

### Fetch the lambdas
* cd lambdas-download
* terraform init
* terraform apply
* cd ..

### Do the needful
* terraform init
* terraform apply

The webhook and secret should be the same every time,
but they go in https://github.com/organizations/compiler-explorer/settings/apps/compiler-explorer-ci


## To update the packer image
* might as well update the git submodule `cd terraform-aws-github-runner; git pull` etc - remember this is _our patched version_ so go ensure that's set up correctly on the right version etc.
* Then `./build-image.sh` and `./build-image-arm64.sh`
* Once built you'll need to rerun the `terraform apply`


## To update the version of the philips code
- update the version in `lambdas-download/main.tf`
- `terraform apply` in `lambdas-download`
- merge tag vX.Y.Z into submodule `terraform-aws-github-runner`
- `terraform init` in toplevel and `terraform apply`