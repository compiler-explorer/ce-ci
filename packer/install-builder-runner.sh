#!/bin/bash -e
# Based off of https://github.com/github-aws-runners/terraform-aws-github-runner/blob/main/modules/runners/templates/install-runner.sh

user_name=$(cat /tmp/install-user.txt)

## install the runner

s3_location=${S3_LOCATION_RUNNER_DISTRIBUTION}
architecture=${RUNNER_ARCHITECTURE}

if [ -z "$RUNNER_TARBALL_URL" ] && [ -z "$s3_location" ]; then
  echo "Neither RUNNER_TARBALL_URL or s3_location are set"
  exit 1
fi

file_name="actions-runner.tar.gz"

echo "Setting up GH Actions runner tool cache"
# Required for various */setup-* actions to work, location is also know by various environment
# variable names in the actions/runner software : RUNNER_TOOL_CACHE / RUNNER_TOOLSDIRECTORY / AGENT_TOOLSDIRECTORY
# Warning, not all setup actions support the env vars and so this specific path must be created regardless
mkdir -p /opt/hostedtoolcache

echo "Creating actions-runner directory for the GH Action installation"
cd /opt/
mkdir -p actions-runner && cd actions-runner


if [[ -n "$RUNNER_TARBALL_URL" ]]; then
  echo "Downloading the GH Action runner from $RUNNER_TARBALL_URL to $file_name"
  curl -o $file_name -L "$RUNNER_TARBALL_URL"
else
  echo "Retrieving TOKEN from AWS API"
  token=$(curl -f -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 180")

  region=$(curl -f -H "X-aws-ec2-metadata-token: $token" -v http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
  echo "Retrieved REGION from AWS API ($region)"

  echo "Downloading the GH Action runner from s3 bucket $s3_location"
  aws s3 cp "$s3_location" "$file_name" --region "$region"
fi

echo "Un-tar action runner"
tar xzf ./$file_name
echo "Delete tar file"
rm -rf $file_name

os_id=$(awk -F= '/^ID/{print $2}' /etc/os-release)
echo OS: $os_id

# Install libicu on non-ubuntu
if [[ ! "$os_id" =~ ^ubuntu.* ]]; then
  max_attempts=5
  attempt_count=0
  success=false
  while [ $success = false ] && [ $attempt_count -le $max_attempts ]; do
    echo "Attempt $attempt_count/$max_attempts: Installing libicu"
    dnf install -y libicu
    if [ $? -eq 0 ]; then
      success=true
    else
      echo "Failed to install libicu"
      attempt_count=$(( attempt_count + 1 ))
      sleep 5
    fi
  done
fi

# Install dependencies for ubuntu
if [[ "$os_id" =~ ^ubuntu.* ]]; then
    echo "Installing dependencies"
    ./bin/installdependencies.sh
fi

echo "Set file ownership of action runner"
chown -R "$user_name":"$user_name" .
chown -R "$user_name":"$user_name" /opt/hostedtoolcache

apt update -y -q && apt upgrade -y -q && apt upgrade -y -q && apt install -y -q \
    bison \
    bzip2 \
    curl \
    file \
    flex \
    gawk \
    git \
    libc6-dev-i386 \
    libc6-dev-arm64-cross \
    libelf-dev \
    linux-libc-dev \
    autoconf \
    automake \
    make \
    binutils-multiarch \
    elfutils \
    ninja-build \
    patch \
    subversion \
    texinfo \
    unzip \
    wget \
    xz-utils \
    libcurl4-openssl-dev

apt-get install -y -q libfreetype6-dev libfontconfig1-dev libglib2.0-dev libgstreamer1.0-dev \
            libgstreamer-plugins-base1.0-dev libice-dev libaudio-dev libgl1-mesa-dev libc6-dev \
            libsm-dev libxcursor-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev \
            libxrandr-dev libxrender-dev libxkbcommon-dev libxkbcommon-x11-dev libx11-dev

apt-get install -y -q libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev \
                libxcb-render0-dev libxcb-render-util0-dev libxcb-randr0-dev libxcb-shape0-dev \
                libxcb-shm0-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev

apt-get install -y -q build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev curl git \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

curl https://pyenv.run | bash

export PYENV_ROOT="/root/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

pyenv install 3.10.16 && \
    pyenv global 3.10.16

mkdir -p /tmp/build

export PATH="/root/.pyenv/shims:/root/.pyenv/versions/3.10.16/bin:$PATH"

python -m pip install conan==1.59

conan remote clean && \
conan remote add ceserver https://conan.compiler-explorer.com/ True
