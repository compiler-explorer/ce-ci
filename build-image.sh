#!/bin/bash

set -euo pipefail

TEMPLATE_FILE=packer/x86.pkr.hcl

# Remember the version of the build comes from the submodules' version
# so update the terraform-aws-github-runner checkout accordingly.

packer init -upgrade -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
packer validate -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
packer build -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
