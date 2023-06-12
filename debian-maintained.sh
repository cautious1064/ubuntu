#!/bin/bash

# 清理未使用的镜像
clean_docker_images() {
  docker image prune -a --force
}

# 清理未使用的卷
clean_docker_volumes() {
  docker volume prune --force
}

# 清理未使用的网络
clean_docker_networks() {
  docker network prune --force
}

# 清理停止的容器
clean_docker_containers() {
  docker container prune --force
}

# 删除容器和相关映射目录
delete_container() {
  read -p "请输入要删除的容器ID: " container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  fi

  echo "正在停止并删除容器 $container_id..."
  docker stop "$container_id"
  docker rm "$container_id"
  echo "容器 $container_id 删除完成！"

  declare -a directories=("/path/to/data" "/path/to/logs")
  for directory in "${directories[@]}"; do
    echo "正在清理容器相关的映射目录 $directory..."
    if [[ -d "$directory" ]]; then
      sudo rm -rf "$directory"
      echo "目录 $directory 清理完成！"
    else
      echo "目录 $directory 不存在。"
    fi
  done

  echo "垃圾清理..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "日志文件清理..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  backup_directory="/path/to/backup"
  echo "备份文件/目录清理..."
  if [[ -d "$backup_directory" ]]; then
    sudo rm -rf "$backup_directory"
    echo "备份文件/目录清理完成！"
  else
    echo "备份目录 $backup_directory 不存在。"
  fi

  echo "系统更新、垃圾清理、日志清理和备份清理完成！"
}

# 安装Docker和Docker Compose
install_docker_and_compose() {
  # 更新系统软件包
  sudo apt update

  # 安装所需的软件包以允许apt通过HTTPS使用存储库
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

  # 添加Docker的官方GPG密钥
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # 添加Docker的APT存储库
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # 更新软件包索引
  sudo apt update

  # 安装Docker引擎
  sudo apt install -y docker-ce docker-ce-cli containerd.io

  # 将当前用户添加到docker组，以免使用sudo运行Docker命令
  sudo usermod -aG docker "$USER"

  # 安装Docker Compose
  compose_version=$(curl -sSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | awk -F / '{print $NF}')
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "Docker和Docker Compose安装完成！"
    echo "Docker版本：$(docker --version)"
    echo "Docker Compose版本：$(docker-compose --version)"
  else
    echo "安装Docker和Docker Compose失败，请检查配置和网络连接。"
  fi
}

# 安装aapanel
install_aapanel() {
  echo "正在下载并执行aapanel安装脚本..."
  wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
  echo "aapanel安装完成！"
}

# 安装casaos
install_casaos() {
  echo "正在安装casaos..."
  curl -fsSL https://get.casaos.io | sudo bash
  echo "casaos安装完成！"
}

# 开启BBR FQ
enable_bbr_fq() {
  # 检查当前系统是否已经开启BBR FQ
  if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR FQ已经开启，无需执行操作。"
  else
    echo "正在开启BBR FQ..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
      echo "BBR FQ已成功开启！"
    else
      echo "无法开启BBR FQ，请检查系统配置。"
    fi
  fi
}

# 清空所有容器日志
clear_container_logs() {
  echo "正在清空所有容器日志..."
  sudo find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "容器日志清理完成！"
}

# 日常维护子功能菜单
maintenance_menu() {
  while true; do
    echo "请选择要执行的日常维护操作:"
    echo "1. 删除容器和相关映射目录"
    echo "2. 清空所有容器日志"
    echo "3. 清理Docker"
    echo "4. 安装Docker和Docker Compose"
    echo "5. 开启BBR FQ"
    echo "6. 返回主菜单"

    read -r choice

    case $choice in
      1)
        delete_container
        ;;
      2)
        clear_container_logs
        ;;
      3)
        docker_cleanup_menu
        ;;
      4)
        install_docker_and_compose
        ;;
      5)
        enable_bbr_fq
        ;;
      6)
        break
        ;;
      *)
        echo "无效的选择，请重新输入。"
        ;;
    esac
  done
}

# Docker清理子功能菜单
docker_cleanup_menu() {
  while true; do
    echo "请选择要执行的Docker清理操作:"
    echo "1. 清理未使用的镜像"
    echo "2. 清理未使用的卷"
    echo "3. 清理未使用的网络"
    echo "4. 清理停止的容器"
    echo "5. 返回上级菜单"

    read -r choice

    case $choice in
      1)
        clean_docker_images
        ;;
      2)
        clean_docker_volumes
        ;;
      3)
        clean_docker_networks
        ;;
      4)
        clean_docker_containers
        ;;
      5)
        break
        ;;
      *)
        echo "无效的选择，请重新输入。"
        ;;
    esac
  done
}

# 主菜单
main_menu() {
  while true; do
    echo "请选择要执行的操作:"
    echo "1. 日常维护"
    echo "2. 安装aapanel"
    echo "3. 安装casaos"
    echo "4. 退出"

    read -r choice

    case $choice in
      1)
        maintenance_menu
        ;;
      2)
        install_aapanel
        ;;
      3)
        install_casaos
        ;;
      4)
        break
        ;;
      *)
        echo "无效的选择，请重新输入。"
        ;;
    esac
  done
}

# 运行主菜单
main_menu
