#!/bin/bash
set -ex

buildkit_file_name="buildkit.tar.gz"

echo "Creating Buildkit directory..."
mkdir -p /opt/buildkit
cd /opt/buildkit
echo "Buildkit directory created: /opt/buildkit"

# Dependencies
yum update -y

echo "Installing dependency: runc..."
yum -y install runc
echo "Dependency installed: runc"

# Buildkit
echo "Downloading Buildkit..."
sudo curl --retry 5 -f --retry-all-errors --retry-delay 5 -o $buildkit_file_name -L "https://github.com/moby/buildkit/releases/download/v0.11.0/buildkit-v0.11.0.linux-amd64.tar.gz"
echo "Downloaded Buildkit to /opt/buildkit/$buildkit_file_name"

echo "Extracting Buildkit .tar"
sudo tar xzf ./$buildkit_file_name
echo "Extracted Buildkit .tar"

echo "Removing .tar..."
sudo rm -rf $buildkit_file_name
echo "Removed .tar"

# Buildkit Config
echo "Creating Buildkit config file..."

sudo mkdir -p /etc/buildkit
sudo cat <<EOF > /etc/buildkit/buildkitd.toml
root = "/var/lib/buildkit"
[grpc]
address = ["tcp://0.0.0.0:8082", "unix:///run/buildkit/buildkitd.sock"]
[worker.oci]
enabled = true
gc = true
gckeepstorage = 20000000000 # 20GB
max-parallelism = 12
[worker.containerd]
enabled = false
[[worker.oci.gcpolicy]]
keepBytes = 10240000000 # 10 GB
keepDuration = 604800
filters = [
  "type==source.local",
  "type==exec.cachemount",
  "type==source.git.checkout",
]
[[worker.oci.gcpolicy]]
keepBytes = 30000000000 # 30 GB
[[worker.oci.gcpolicy]]
all = true
keepBytes = 30000000000 # 30 GB
EOF

echo "Buildkit config file created"
