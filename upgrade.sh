#!/bin/bash

# Check if the script is run with sudo/root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo or root privileges."
  exit 1
fi

# Clear existing software package sources
echo "Clearing existing software package sources..."
rm /etc/apt/sources.list
echo "" > /etc/apt/sources.list

# Add official Ubuntu sources
echo "Adding official Ubuntu sources..."
cat <<EOF > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse
EOF

# Update software package lists
echo "Updating software package lists..."
apt update

# Install update-manager-core
echo "Installing update-manager-core..."
apt install -y update-manager-core

# Perform the version upgrade
echo "Performing Ubuntu version upgrade..."
do-release-upgrade

# Check the exit status of do-release-upgrade
if [ $? -eq 0 ]; then
  echo "Ubuntu version upgrade completed successfully."
else
  echo "Ubuntu version upgrade encountered some issues. Please check the output above for details."
fi
