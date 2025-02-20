#!/bin/bash

set -euo pipefail

packer init -upgrade -var-file=packer-vars-win-builder.hcl packer/gha-win-builder.pkr.hcl
packer validate -var-file=packer-vars-win-builder.hcl packer/gha-win-builder.pkr.hcl
packer build -var-file=packer-vars-win-builder.hcl packer/gha-win-builder.pkr.hcl
