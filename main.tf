locals {
  environment = "ce-ci"
  aws_region  = "us-east-1"
}

resource "random_password" "random" {
  length = 28
}

module "runners" {
  source = "philips-labs/github-runner/aws"
  version = "1.10.0"

  aws_region = local.aws_region
  vpc_id     = "vpc-17209172"
  subnet_ids = ["subnet-690ed81e", "subnet-1bed1d42"]

  prefix = local.environment
  tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
  }

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    webhook_secret = random_password.random.result
  }

  webhook_lambda_zip                = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas-download/runners.zip"

  enable_organization_runners = true
  runner_extra_labels         = "ubuntu,ce"

  instance_types = [
    "c5.8xlarge",
    "c5a.8xlarge",
    "c6i.8xlarge",
    "c6a.8xlarge",
    "c5.16xlarge",
    "c5a.16xlarge",
    "c6i.16xlarge",
    "c6a.16xlarge",
  ]

  # TODO I had to add the group manually to the EFS thing, this didn't work, but leaving here for thinking
  runner_additional_security_group_ids = ["sg-0efc9951eaa9b5233"]  # BuilderNodeSecGroup
  # enable access to the runners via SSM
  enable_ssm_on_runners = true

  runner_run_as     = "ubuntu"
  userdata_template = "./templates/user-data.sh"
  ami_owners        = ["099720109477"] # Canonical's Amazon account ID

  ami_filter = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  block_device_mappings = [
    {
     # Set the block device name for Ubuntu root device
      device_name = "/dev/sda1"
      delete_on_termination = true
      encrypted = false
      iops = null
      kms_key_id = null
      snapshot_id = null
      throughput = null
      volume_size = 30
      volume_type = "gp3"
    }
  ]

  runner_log_files = [
    {
      "log_group_name" : "syslog",
      "prefix_log_group" : true,
      "file_path" : "/var/log/syslog",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : "/var/log/user-data.log",
      "log_stream_name" : "{instance_id}/user_data"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : "/home/runners/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}/runner"
    }
  ]

  runners_maximum_count = 8
}
