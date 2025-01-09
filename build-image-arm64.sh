#!/bin/bash

set -euo pipefail

packer init -upgrade -var-file=packer-vars-arm64.hcl packer/gha.pkr.hcl
packer validate -var-file=packer-vars-arm64.hcl packer/gha.pkr.hcl
packer build -var-file=packer-vars-arm64.hcl packer/gha.pkr.hcl
