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

# Stop and disable node exporter service if it exists
if systemctl is-active --quiet node_exporter; then
  sudo systemctl stop node_exporter
  sudo systemctl disable node_exporter
fi

# Check if node exporter binary exists and remove it
if [ -f /usr/local/bin/node_exporter ]; then
  sudo rm -f /usr/local/bin/node_exporter
else
  echo "Node exporter binary not found in /usr/local/bin"
  exit 1
fi

# Determine the appropriate release URL based on architecture
release_url=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
  | grep "browser_download_url" \
  | grep "$(get_architecture)" \
  | cut -d : -f 2,3 \
  | tr -d "\"")

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
