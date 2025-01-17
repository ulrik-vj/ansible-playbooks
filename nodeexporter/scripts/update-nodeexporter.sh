#!/bin/bash

# Function to determine architecture
get_architecture() {
  arch=$(uname -m)
  case $arch in
    armv6l)
      echo "linux-armv6.tar.gz"
      ;;
    armv7l)
      echo "linux-armv7.tar.gz"
      ;;
    aarch64)
      echo "linux-arm64.tar.gz"
      ;;
    x86_64)
      echo "linux-amd64.tar.gz"
      ;;
    *)
      echo "Unsupported architecture: $arch"
      exit 1
      ;;
  esac
}

# Fetch the latest version from GitHub and remove the 'v'
latest_version=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r '.tag_name' | sed 's/^v//')

# Fetch the running version of Node Exporter
running_version=$(/usr/local/bin/node_exporter --version | grep -oP 'version \K[0-9]+\.[0-9]+\.[0-9]+')

# Compare versions and exit if they match
if [ "$latest_version" == "$running_version" ]; then
    echo "Node Exporter is already the latest version ($latest_version). Exiting script."
    exit 0
fi

# Proceed with update logic if versions don't match
echo "Node Exporter is outdated. Running version: $running_version, Latest version: $latest_version. Proceeding with update..."

# Determine the appropriate release URL based on architecture
release_url=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
  | grep "browser_download_url" \
  | grep "$(get_architecture)" \
  | cut -d : -f 2,3 \
  | tr -d "\"")
  
# Stop and disable node exporter service if it exists
if systemctl is-active --quiet node_exporter; then
  sudo systemctl stop node_exporter
  sudo systemctl disable node_exporter
fi

# Check if node exporter binary exists and remove it. So we can replace with new one.
if [ -f /usr/local/bin/node_exporter ]; then
  sudo rm -f /usr/local/bin/node_exporter
fi

# Download the latest node exporter release
wget -q $release_url

# Extract the downloaded tar.gz file
tar -xvzf node_exporter*.tar.gz

# Move the new binary to /usr/local/bin
sudo mv node_exporter*/node_exporter /usr/local/bin/

# Clean up
rm -r node_exporter*.tar.gz node_exporter*/

# Set ownership and permissions
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter

# Enable and start node exporter service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Echo success message
echo "Node exporter updated successfully on $(hostname)."
