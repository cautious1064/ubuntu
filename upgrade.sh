#!/bin/bash

# Check if the script is run with sudo/root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo or root privileges."
  exit 1
fi

# Function to backup and remove all PPAs
remove_ppas() {
  echo "Backing up and removing non-Ubuntu official sources (PPAs)..."
  mkdir -p ~/ppa_backups
  grep -hPo '^deb\s+\K[^ ]+' /etc/apt/sources.list /etc/apt/sources.list.d/*.list | 
  while IFS= read -r ppa; do
    ppa_name=$(echo "$ppa" | sed 's/.*ppa.launchpad.net\///;s/\/.*$//')
    echo "Backing up PPA: $ppa_name"
    sudo apt-add-repository -y --remove "ppa:$ppa_name" 2>/dev/null
    sudo mv "/etc/apt/sources.list.d/${ppa_name}-"* ~/ppa_backups/
  done
  echo "Updating software package lists after removing PPAs..."
  apt update
}

# Update software package lists
echo "Updating software package lists..."
apt update

# Install update-manager-core
echo "Installing update-manager-core..."
apt install -y update-manager-core

# Remove non-Ubuntu official sources (PPAs)
remove_ppas

# Perform the version upgrade
echo "Performing Ubuntu version upgrade..."
do-release-upgrade

# Check the exit status of do-release-upgrade
if [ $? -eq 0 ]; then
  echo "Ubuntu version upgrade completed successfully."
else
  echo "Ubuntu version upgrade encountered some issues. Please check the output above for details."
fi
