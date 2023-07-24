#!/bin/bash

# Check if the script is run with sudo/root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo or root privileges."
  exit 1
fi

# Update software package lists
echo "Updating software package lists..."
apt update
apt upgrade -y

# Install update-manager-core
echo "Installing update-manager-core..."
apt install -y update-manager-core

# Modify the sources.list file
sources_list="/etc/apt/sources.list"
backup_sources_list="/etc/apt/sources.list.bak"
if [ -f "$sources_list" ]; then
  echo "Backing up existing sources.list to $backup_sources_list"
  cp "$sources_list" "$backup_sources_list"
fi

# Add official Ubuntu sources
echo "Adding official Ubuntu sources..."
cat <<EOF > "$sources_list"
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse
EOF

# Update software package lists again
echo "Updating software package lists..."
apt update

# Perform the version upgrade with automatic "yes" to prompts
export DEBIAN_FRONTEND=noninteractive
echo "Performing Ubuntu version upgrade..."
do-release-upgrade -f DistUpgradeViewNonInteractive

# Check the exit status of do-release-upgrade
if [ $? -eq 0 ]; then
  echo "Ubuntu version upgrade completed successfully."
else
  echo "Ubuntu version upgrade encountered some issues. Please check the output above for details."
fi
