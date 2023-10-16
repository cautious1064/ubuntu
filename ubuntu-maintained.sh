#!/bin/bash

# Function to install Docker and Docker Compose
install_docker_and_compose() {
  echo "Updating system packages..."
  sudo apt update
  echo "Installing Docker Engine..."
  sudo apt install docker.io
  echo "Installing Docker Compose..."
  sudo apt install docker-compose
  sudo apt install -y jq

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "Successfully installed Docker and Docker Compose!"
    echo "Docker version: $(docker --version)"
    echo "Docker Compose version: $(docker-compose --version)"
  else
    echo "Failed to install Docker and Docker Compose. Please check your configuration and network connection."
  fi
}

# Function to enable BBR FQ
enable_bbr_fq() {
  # Check if BBR FQ is already enabled
  if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR FQ is already enabled, no further action needed."
  else
    echo "Enabling BBR FQ..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
      echo "BBR FQ enabled successfully!"
    else
      echo "Failed to enable BBR FQ. Please check your system configuration."
    fi
  fi
}

# Function to clear all container logs
clear_container_logs() {
  echo "Clearing all container logs..."
  sudo find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "Container logs cleaned!"
}

# Function to update and clean the system
update_and_cleanup_system() {
  echo "Updating software packages and basic tools..."
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install curl sudo neofetch vim jq -y
  echo "Software package updates completed!"

  echo "Cleaning up system..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "System cleanup completed!"

  echo "Cleaning up log files..."
  sudo find /var/log -type f -delete
  echo "Log file cleanup completed!"

  backup_directory="/path/to/backup"
  echo "Cleaning backup files/directories..."
  if [[ -d "$backup_directory" ]]; then
    sudo rm -rf "$backup_directory"
    echo "Backup file/directory cleanup completed!"
  else
    echo "Backup directory $backup_directory does not exist."
  fi

  echo "Removing unused kernels..."
  sudo apt purge $(dpkg --list | grep '^rc' | awk '{print $2}') -y

  echo "Cleaning cache files..."
  sudo apt clean

  echo "System updates, garbage cleanup, log cleanup, backup cleanup, unused kernel cleanup, and cache cleanup completed!"
}

# Function to delete a specific Docker container and related mapped directories
delete_container() {
  read -p "Enter the ID of the container to delete: " container_id

  if [ -z "$container_id" ]; then
    echo "Container ID not provided."
    return
  fi

  # Get container's mapped directories
  container_info=$(sudo docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "Unable to retrieve container's mapped directory information."
    return
  fi

  # Parse container's mapped directory paths
  declare -a directories=()
  mapfile -t directories < <(echo "$container_info" | jq -r '.[].Source')

  if [ ${#directories[@]} -eq 0 ]; then
    echo "Container has no mapped directories."
    return
  fi

  echo "Stopping and deleting container $container_id..."
  sudo docker stop "$container_id"
  sudo docker rm "$container_id"
  echo "Container $container_id deleted!"

  # Delete the container's mapped directories
  for directory in "${directories[@]}"; do
    if [ -d "$directory" ]; then
      echo "Deleting mapped directory $directory..."
      sudo rm -rf "$directory"
      echo "Mapped directory $directory deleted!"
    fi
  done

  echo "Garbage cleanup..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "Garbage cleanup completed!"

  echo "Cleaning log files..."
  sudo find /var/log -type f -delete
  echo "Log file cleanup completed!"

  echo "Container and related mapped directory deletion completed!"
}

# Main menu
show_main_menu() {
  clear
  echo "Script Function List"
  echo "1. Install Docker and Docker Compose"
  echo "2. Enable BBR FQ"
  echo "3. Clear all container logs"
  echo "4. Update and clean the system"
  echo "5. Delete a specific Docker container and related mapped directories"
  echo "0. Exit"
  echo
  read -p "Enter the option number: " option
  echo

  case $option in
    1) install_docker_and_compose ;;
    2) enable_bbr_fq ;;
    3) clear_container_logs ;;
    4) update_and_cleanup_system ;;
    5) delete_container ;;
    0) exit ;;
    *) echo "Invalid option. Please enter a valid option." ;;
  esac

  echo
  read -p "Press Enter to return to the main menu."
  show_main_menu
}

# Show the main menu
show_main_menu
