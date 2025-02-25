custom_shell_commands = [
"mkdir C:/tmp/infra",
"git clone https://github.com/compiler-explorer/infra C:/tmp/infra",
"C:/tmp/infra/packer/InstallPwsh.ps1",
"C:/tmp/infra/packer/InstallBuilderTools.ps1"
]
arch = "amd64"
instance_type = "c5.large"
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
