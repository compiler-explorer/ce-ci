#!/bin/bash

set -euo pipefail

TEMPLATE_FILE=terraform-aws-github-runner/images/ubuntu-jammy/github_agent.ubuntu.pkr.hcl

# REMEMBER TO UPDATE OUR PATCHED VERSION OF terraform-aws-github-runner

packer init -upgrade -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
packer validate -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
packer build -var-file=packer-vars.hcl "${TEMPLATE_FILE}"
