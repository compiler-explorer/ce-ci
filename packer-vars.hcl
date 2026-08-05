custom_shell_commands = [
"sudo mkdir /infra",
"sudo chown ubuntu: /infra",
"git clone https://github.com/compiler-explorer/infra /infra",
"sudo /infra/setup-ci.sh"
]
arch = "amd64"
instance_type = "c5.large"
# Noble plus the i386 packages overflows the 8GB default while unpacking the
# runner tarball. Runners launch with their own 128GB volume, so this only
# sizes the build and the AMI snapshot.
root_volume_size_gb = 32
runner_version = "2.335.1"
region = "us-east-1"
security_group_id = "sg-f53f9f80" # AdminNode (so we can ssh to it) just for builds
subnet_id = "subnet-690ed81e"
associate_public_ip_address = "true"
global_tags = {
    Site = "CompilerExplorer"
    Subsystem = "CI"
}
iam_instance_profile = "XaniaBlog"
