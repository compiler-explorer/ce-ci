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
* might as well update the git submodule `cd aws-github-runner; git pull` etc
* Then ./build-image.sh
* Once built you'll need to rerun the `terraform apply`
