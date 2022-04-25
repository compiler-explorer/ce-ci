#!/bin/bash -x
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

${pre_install}

# Install AWS CLI
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    awscli \
    jq \
    curl \
    wget \
    git \
    uidmap \
    build-essential \
    nfs-client \
    unzip

USER_NAME=ubuntu
USER_ID=$(id -ru $USER_NAME)

# install and configure cloudwatch logging agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}

# configure systemd for running service in users accounts
cat >/etc/systemd/user@UID.service <<-EOF

[Unit]
Description=User Manager for UID %i
After=user-runtime-dir@%i.service
Wants=user-runtime-dir@%i.service

[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
User=%i
PAMName=systemd-user
Type=notify

[Install]
WantedBy=default.target

EOF

echo export XDG_RUNTIME_DIR=/run/user/$USER_ID >>/home/$USER_NAME/.profile

systemctl daemon-reload
systemctl enable user@UID.service
systemctl start user@UID.service

curl -fsSL https://get.docker.com/rootless >>/opt/rootless.sh && chmod 755 /opt/rootless.sh
su -l $USER_NAME -c /opt/rootless.sh
echo export DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>/home/$USER_NAME/.profile
echo export PATH=/home/$USER_NAME/bin:$PATH >>/home/$USER_NAME/.profile

# Run docker service by default
loginctl enable-linger $USER_NAME
su -l $USER_NAME -c "systemctl --user enable docker"

${install_runner}

# config runner for rootless docker
cd /opt/actions-runner/
echo DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>.env
echo PATH=/home/$USER_NAME/bin:$PATH >>.env

# Mount /efs
mkdir -p /efs
echo "fs-db4c8192.efs.us-east-1.amazonaws.com:/ /efs nfs nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >>/etc/fstab
mount -a

# install build packages for ce
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3.8-venv \
    squashfs-tools \
    libncurses5

ln -s /efs/squash-images /opt/squash-images
ln -s /efs/compiler-explorer /opt/compiler-explorer
ln -s /efs/wine-stable /opt/wine-stable

${post_install}

cd /opt/actions-runner

${start_runner}
