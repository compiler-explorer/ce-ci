custom_shell_commands = [
]
arch = "amd64"
instance_type = "c5.large"
runner_version = "2.321.0"
region = "us-east-1"
security_group_id = "sg-06f4355d49a1e117b"
subnet_id = "subnet-690ed81e"
associate_public_ip_address = "true"
global_tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
}
iam_instance_profile = "XaniaBlog"
