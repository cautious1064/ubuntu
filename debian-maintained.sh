#!/bin/bash

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

# Docker容器备份
mkdir -p /path/to/backup
backup_container() {
  read -p "请输入要备份的容器ID: " container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  fi

  # 获取容器信息
  container_info=$(sudo docker inspect --format='{{json .}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "无法获取容器信息。"
    return
  fi

  # 获取容器名称
  container_name=$(echo "$container_info" | jq -r '.Name' | sed 's/\///g')
  if [ -z "$container_name" ]; then
    echo "无法获取容器名称。"
    return
  fi

  # 指定备份目录
  backup_directory="/path/to/backup"
  if [ ! -d "$backup_directory" ]; then
    echo "备份目录 $backup_directory 不存在。"
    return
  fi

  # 备份容器
  echo "正在备份容器 $container_id..."
  backup_filename="${container_name}_$(date +%Y%m%d%H%M%S).tar.gz"
  sudo docker export "$container_id" | gzip > "$backup_directory/$backup_filename"
  echo "容器 $container_id 备份完成！备份文件路径: $backup_directory/$backup_filename"
}

# Docker容器恢复
mkdir -p /path/to/restore
restore_container() {
  read -p "请输入要恢复的容器备份文件路径: " backup_file

  if [ -z "$backup_file" ]; then
    echo "未提供备份文件路径。"
    return
  fi

  if [ ! -f "$backup_file" ]; then
    echo "备份文件 $backup_file 不存在。"
    return
  fi

  # 指定恢复目录
  restore_directory="/path/to/restore"
  if [ ! -d "$restore_directory" ]; then
    echo "恢复目录 $restore_directory 不存在。"
    return
  fi

  # 解压备份文件
  echo "正在解压备份文件 $backup_file..."
  sudo tar xf "$backup_file" -C "$restore_directory"
  echo "备份文件 $backup_file 解压完成！"

  # 恢复容器
  echo "正在恢复容器..."
  container_id=$(sudo docker create $(sudo find "$restore_directory" -name '*.json' -exec cat {} \;))
  if [ -n "$container_id" ]; then
    sudo docker cp "$restore_directory" "$container_id:/"
    sudo docker start "$container_id"
    echo "容器恢复完成！容器ID: $container_id"
  else
    echo "无法创建容器。"
  fi
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
  echo "8. Docker容器备份"
  echo "9. Docker容器恢复"
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
    8) backup_container ;;
    9) restore_container ;;
    0) exit ;;
    *) echo "无效的选项。请重新输入。" ;;
  esac

  echo
  read -p "按Enter键返回主菜单。" enter_key
  show_main_menu
}

# 显示主菜单
show_main_menu
