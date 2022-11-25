#!/bin/bash

set -euo pipefail

TEMPLATE_FILE=terraform-aws-github-runner/images/ubuntu-focal/github_agent.ubuntu.pkr.hcl

packer validate -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
packer build -var-file=packer-vars.hcl "${TEMPLATE_FILE}"