# Upgrade terraform-aws-github-runner Module

Upgrade the terraform-aws-github-runner module to a newer version.

## Prerequisites

You should have:
- GitHub CLI (`gh`) installed and authenticated
- Terraform installed
- AWS credentials configured

## Steps

### 1. Check Current Version

Current versions are in:
- `lambdas-download/main.tf` (line 2, `version` local)
- `main.tf` (line 20, module version)

### 2. Find Latest Release

Use GitHub CLI to check available releases:

```bash
gh release list --repo github-aws-runners/terraform-aws-github-runner --limit 10
```

### 3. Review Release Notes

Check release notes for any breaking changes between current and target version.

For major/minor version jumps, review multiple release notes:

```bash
gh release view v6.6.0 --repo github-aws-runners/terraform-aws-github-runner
gh release view v6.7.0 --repo github-aws-runners/terraform-aws-github-runner
gh release view v6.8.0 --repo github-aws-runners/terraform-aws-github-runner
```

Look for:
- Breaking changes
- New features that might affect configuration
- Deprecated features
- Migration notes

### 4. Update Lambda Downloader

**Edit `lambdas-download/main.tf`:**
- Update the `version` local to new version (line 2)

**Download new Lambda functions:**
```bash
cd lambdas-download
terraform apply -auto-approve
cd ..
```

### 5. Update Main Module

**Edit `main.tf`:**
- Update module `version` to new version (line 20)

**Initialize Terraform with new module:**
```bash
terraform init -upgrade
```

### 6. Create and Review Plan

**IMPORTANT:** Always create a plan file in `/tmp` for review:

```bash
terraform plan -out=/tmp/ce-ci-upgrade-v<VERSION>.tfplan
```

**Review the plan:**
- Check the summary (X to add, Y to change, Z to destroy)
- Look for unexpected changes
- Verify IAM role replacements are expected
- Check Lambda function updates

**Common expected changes:**
- Lambda functions updated in-place (new source code)
- IAM roles replaced (Terraform adds hash suffixes in newer versions)
- IAM policies replaced (attached to new roles)
- Launch templates changed (references to new IAM roles)
- New IAM policies for new features

### 7. Apply the Plan

**ONLY after reviewing the plan:**

```bash
terraform apply /tmp/ce-ci-upgrade-v<VERSION>.tfplan
```

## Critical Gotchas

### Working Directory
**CRITICAL:** Make sure you're in the correct directory!
- Lambda downloads: Run from `lambdas-download/` directory
- Main infrastructure: Run from **top-level** directory (NOT lambdas-download!)

### Plan Files
- Always use `/tmp/` for plan files (don't clutter the repo)
- Use descriptive names: `ce-ci-upgrade-v6.8.2.tfplan`
- **NEVER** apply without reviewing the plan first

### No Webhook Changes
- Webhook URL and secret should remain the same
- If they change unexpectedly, investigate before applying

### AMI Rebuilds
- Module upgrades typically **do not** require AMI rebuilds
- Only rebuild AMIs if:
  - Packer configuration changes
  - GitHub Actions runner version changes
  - Base OS changes

## Post-Upgrade

After successful apply:

1. Monitor CloudWatch logs for Lambda functions
2. Test runner provisioning by triggering a workflow
3. Update this command if process changes
4. Commit the version changes:
   - `lambdas-download/main.tf`
   - `main.tf`
   - `.terraform.lock.hcl` (both directories)

## Rollback

If issues occur:
1. Update versions back to previous version
2. Run `terraform init -upgrade` again
3. Apply to revert changes

## Example Session

```bash
# Check current version
grep 'version' lambdas-download/main.tf
grep 'version.*=' main.tf | head -1

# Find latest
gh release list --repo github-aws-runners/terraform-aws-github-runner --limit 10

# Review release notes
gh release view v6.8.2 --repo github-aws-runners/terraform-aws-github-runner

# Update lambdas
# Edit lambdas-download/main.tf
cd lambdas-download && terraform apply -auto-approve && cd ..

# Update main
# Edit main.tf
terraform init -upgrade
terraform plan -out=/tmp/ce-ci-upgrade-v6.8.2.tfplan

# Review, then apply
terraform apply /tmp/ce-ci-upgrade-v6.8.2.tfplan
```

## References

- [terraform-aws-github-runner releases](https://github.com/github-aws-runners/terraform-aws-github-runner/releases)
- README.md section: "To update the version of the github-aws-runners code"
