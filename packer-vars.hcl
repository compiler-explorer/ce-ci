custom_shell_commands = [
"sudo apt-get install -y build-essential curl nfs-client python3.9 python3.9-venv squashfs-tools libncurses5",
"sudo mkdir /infra",
"sudo chown ubuntu: /infra",
"git clone https://github.com/compiler-explorer/infra /infra",
"sudo /infra/setup-ci.sh"
]
instance_type = "c5.large"
runner_version = "2.299.1"
region = "us-east-1"
security_group_id = "sg-f53f9f80" # AdminNode (so we can ssh to it) just for builds
subnet_id = "subnet-690ed81e"
associate_public_ip_address = "true"
global_tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
}
iam_instance_profile = "XaniaBlog"
