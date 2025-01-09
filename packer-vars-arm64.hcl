custom_shell_commands = [
"sudo mkdir /infra",
"sudo chown ubuntu: /infra",
"git clone https://github.com/compiler-explorer/infra /infra",
"sudo /infra/setup-ci.sh"
]
arch = "arm64"
instance_type = "r7g.large"
runner_version = "2.321.0"
region = "us-east-1"
security_group_id = "sg-f53f9f80" # AdminNode (so we can ssh to it) just for builds
subnet_id = "subnet-690ed81e"
associate_public_ip_address = "true"
global_tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
}
iam_instance_profile = "XaniaBlog"
