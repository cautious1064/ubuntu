#!/bin/bash

# Install Docker and Docker Compose
install_docker_and_compose() {
  # Update the system packages
  sudo dnf update -y
  # Install Docker Engine
  sudo dnf install -y dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker
  sudo systemctl enable docker
  # Install Docker Compose
  sudo dnf install -y curl jq
  compose_version=$(curl -sSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | awk -F / '{print $NF}')
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "Docker and Docker Compose installed successfully!"
    echo "Docker version: $(docker --version)"
    echo "Docker Compose version: $(docker-compose --version)"
  else
    echo "Failed to install Docker and Docker Compose. Please check the configuration and network connectivity."
  fi
}

# Install aaPanel
install_aapanel() {
  echo "Downloading and executing aaPanel installation script..."
  wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
  echo "aaPanel installation completed!"
}

# Install CasaOS
install_casaos() {
  echo "Installing CasaOS..."
  curl -fsSL https://get.casaos.io | sudo bash
  echo "CasaOS installation completed!"
}

# Enable BBR FQ
enable_bbr_fq() {
  # Check if BBR FQ is already enabled
  if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR FQ is already enabled. No further action required."
  else
    echo "Enabling BBR FQ..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
      echo "BBR FQ enabled successfully!"
    else
      echo "Failed to enable BBR FQ. Please check the system configuration."
    fi
  fi
}

# Clear all container logs
clear_container_logs() {
  echo "Clearing all container logs..."
  sudo find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "Container logs cleared!"
}

# Update and cleanup the system
update_and_cleanup_system() {
  echo "Updating packages and basic tools..."
  dnf update -y
  dnf install -y curl sudo neofetch vim
  echo "Package updates completed!"

  echo "Cleaning up junk files..."
  sudo dnf autoremove -y
  sudo dnf clean all
  echo "Junk cleanup completed!"

  echo "Cleaning up log files..."
  sudo journalctl --vacuum-time=7d
  echo "Log files cleanup completed!"

  backup_directory="/path/to/backup"
  echo "Cleaning up backup files/directories..."
  if [[ -d "$backup_directory" ]]; then
    sudo rm -rf "$backup_directory"
    echo "Backup files/directories cleaned up!"
  else
    echo "Backup directory $backup_directory does not exist."
  fi

  echo "System update, junk cleanup, log cleanup, and backup cleanup completed!"
}

# Delete specified Docker container and related mount directories
delete_container() {
  read -p "Enter the container ID to delete: " container_id

  if [ -z "$container_id" ]; then
    echo "Container ID not provided."
    return
  fi

  # Get the mount directories of the container
  container_info=$(sudo docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "Failed to retrieve mount directory information of the container."
    return
  fi

  # Parse the mount directory paths of the container
  declare -a directories=()
  mapfile -t directories < <(echo "$container_info" | jq -r '.[].Source')

  if [ ${#directories[@]} -eq 0 ]; then
    echo "The container does not have any mount directories."
    return
  fi

  echo "Stopping and deleting container $container_id..."
  sudo docker stop "$container_id"
  sudo docker rm "$container_id"
  echo "Container $container_id deleted!"

  # Delete the mount directories of the container
  for directory in "${directories[@]}"; do
    if [ -d "$directory" ]; then
      echo "Deleting mount directory $directory..."
      sudo rm -rf "$directory"
      echo "Mount directory $directory deleted!"
    fi
  done

  # Other cleanup operations...

  echo "Junk cleanup..."
  sudo dnf autoremove -y
  sudo dnf clean all
  echo "Junk cleanup completed!"

  echo "Cleaning up log files..."
  sudo journalctl --vacuum-time=7d
  echo "Log files cleanup completed!"

  # Other cleanup operations...

  echo "Container and related mount directories deleted!"
}

# Main menu
show_main_menu() {
  clear
  echo "Script Function List"
  echo "1. Install Docker and Docker Compose"
  echo "2. Install aaPanel"
  echo "3. Install CasaOS"
  echo "4. Enable BBR FQ"
  echo "5. Clear all container logs"
  echo "6. Update and cleanup the system"
  echo "7. Delete specified Docker container and related mount directories"
  echo "0. Exit"
  echo
  read -p "Enter the option number: " option
  echo

  case $option in
    1) install_docker_and_compose ;;
    2) install_aapanel ;;
    3) install_casaos ;;
    4) enable_bbr_fq ;;
    5) clear_container_logs ;;
    6) update_and_cleanup_system ;;
    7) delete_container ;;
    0) exit ;;
    *) echo "Invalid option. Please enter a valid option." ;;
  esac

  echo
  read -p "Press Enter to return to the main menu." enter_key
  show_main_menu
}

# Show the main menu
show_main_menu
