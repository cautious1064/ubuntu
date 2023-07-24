#!/bin/bash

# 安装Docker和Docker Compose
install_docker_and_compose() {
  # 更新系统软件包
  sudo apt update
  # 安装Docker引擎
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  # 安装Docker Compose
  compose_version=$(curl -sSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | awk -F / '{print $NF}')
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo apt install -y jq

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "Docker和Docker Compose安装完成！"
    echo "Docker版本：$(docker --version)"
    echo "Docker Compose版本：$(docker-compose --version)"
  else
    echo "安装Docker和Docker Compose失败，请检查配置和网络连接。"
  fi
}

# 安装aaPanel
install_aapanel() {
  echo "正在下载并执行aaPanel安装脚本..."
  wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
  echo "aaPanel安装完成！"
}

# 安装CasaOS
install_casaos() {
  echo "正在安装CasaOS..."
  curl -fsSL https://get.casaos.io | sudo bash
  echo "CasaOS安装完成！"
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

# 更新和清理系统
update_and_cleanup_system() {
  echo "正在更新软件包和基础工具..."
  apt update -y
  apt upgrade -y
  apt install curl sudo neofetch vim -y
  echo "软件包更新完成！"

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

# 删除指定的Docker容器和相关映射目录
delete_container() {
  read -p "请输入要删除的容器ID: " container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  fi

  # 获取容器的映射目录
  container_info=$(sudo docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "无法获取容器的映射目录信息。"
    return
  fi

  # 解析容器的映射目录路径
  declare -a directories=()
  mapfile -t directories < <(echo "$container_info" | jq -r '.[].Source')

  if [ ${#directories[@]} -eq 0 ]; then
    echo "容器没有映射目录。"
    return
  fi

  echo "正在停止并删除容器 $container_id..."
  sudo docker stop "$container_id"
  sudo docker rm "$container_id"
  echo "容器 $container_id 删除完成！"

  # 删除容器的映射目录
  for directory in "${directories[@]}"; do
    if [ -d "$directory" ]; then
      echo "正在删除映射目录 $directory..."
      sudo rm -rf "$directory"
      echo "映射目录 $directory 删除完成！"
    fi
  done

  # 其他清理操作...

  echo "垃圾清理..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "日志文件清理..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  # 其他清理操作...

  echo "删除容器和相关映射目录完成！"
}

# 主菜单
show_main_menu() {
  clear
  echo "脚本功能列表"
  echo "1. 安装Docker和Docker Compose"
  echo "2. 安装aaPanel"
  echo "3. 安装CasaOS"
  echo "4. 开启BBR FQ"
  echo "5. 清空所有容器日志"
  echo "6. 更新和清理系统"
  echo "7. 删除指定的Docker容器和相关映射目录"
  echo "0. 退出"
  echo
  read -p "请输入选项数字: " option
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
    *) echo "无效的选项。请重新输入。" ;;
  esac

  echo
  read -p "按Enter键返回主菜单。" enter_key
  show_main_menu
}

# 显示主菜单
show_main_menu
