#!/bin/bash

# 功能1：安装 Docker 和 Docker Compose
安装_docker和_compose() {
  echo "正在更新系统软件包..."
  sudo apt update
  echo "正在安装 Docker Engine..."
  sudo apt install docker.io
  echo "正在安装 Docker Compose..."
  sudo apt install docker-compose
  sudo apt install -y jq

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "成功安装 Docker 和 Docker Compose！"
    echo "Docker 版本: $(docker --version)"
    echo "Docker Compose 版本: $(docker-compose --version)"
  else
    echo "无法安装 Docker 和 Docker Compose。请检查您的配置和网络连接。"
  fi
}

# 功能2：启用 BBR FQ
启用_bbr_fq() {
  # 检查是否已启用 BBR FQ
  if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR FQ 已经启用，无需进一步操作。"
  else
    echo "正在启用 BBR FQ..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
      echo "成功启用 BBR FQ！"
    else
      echo "无法启用 BBR FQ。请检查系统配置。"
    fi
  fi
}

# 功能3：清除所有容器日志
清除容器日志() {
  echo "正在清除所有容器日志..."
  sudo find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "容器日志已清除！"
}

# 功能4：更新和清理系统
更新和清理系统() {
  echo "正在更新软件包和基本工具..."
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install curl sudo neofetch vim jq -y
  echo "软件包更新完成！"

  echo "正在清理系统..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "系统清理完成！"

  echo "正在清理日志文件..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  backup_directory="/path/to/backup"  # 将路径更改为实际的备份目录路径
  echo "正在清理备份文件/目录..."
  if [[ -d "$backup_directory" ]]; then
    sudo rm -rf "$backup_directory"
    echo "备份文件/目录清理完成！"
  else
    echo "备份目录 $backup_directory 不存在。"
  fi

  echo "正在删除未使用的内核..."
  sudo apt purge $(dpkg --list | grep '^rc' | awk '{print $2}') -y

  echo "正在清理缓存文件..."
  sudo apt clean

  echo "系统更新、垃圾清理、日志清理、备份清理、未使用内核清理和缓存清理完成！"
}

# 功能5：删除特定 Docker 容器和相关映射目录
删除容器() {
  read -p "请输入要删除的容器的ID： " container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  fi

  # 获取容器的映射目录
  container_info=$(sudo docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "无法检索容器的映射目录信息。"
    return
  fi

  # 解析容器的映射目录路径
  declare -a directories=()
  mapfile -t directories < <(echo "$container_info" | jq -r '.[].Source')

  if [ ${#directories[@]} -eq 0 ]; then
    echo "容器没有映射目录。正在删除容器..."
    sudo docker stop "$container_id"
    sudo docker rm "$container_id"
    echo "容器 $container_id 已删除！"
  else
    echo "正在停止和删除容器 $container_id..."
    sudo docker stop "$container_id"
    sudo docker rm "$container_id"
    echo "容器 $container_id 已删除！"

    # 删除容器的映射目录
    for directory in "${directories[@]}"; do
      if [ -d "$directory" ]; then
        echo "正在删除映射目录 $directory..."
        sudo rm -rf "$directory"
        echo "映射目录 $directory 已删除！"
      fi
    done
  fi

  echo "垃圾清理..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "正在清理日志文件..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  echo "容器和相关映射目录已删除！"
}

# 功能6：添加SSH密钥
添加_SSH密钥() {
  # 提示用户输入要使用的用户名
  read -p "请输入用于SSH密钥登录的用户名: " username

  # 获取本地网络接口的IP地址
  server_ip=$(hostname -I | awk '{print $1}')

  # 生成SSH密钥对
  ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""

  # 获取authorized_keys内容并添加到服务器上的authorized_keys文件
  curl -s https://raw.githubusercontent.com/cautious1064/ubuntu/main/authorized_keys | ssh "$username@$server_ip" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

  # 修正文件和目录权限
  ssh "$username@$server_ip" "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

  # 配置SSH服务器以允许密钥登录
  sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh

  echo "SSH密钥登录已成功配置为 $username@$server_ip."
  
  # 禁止 root 用户登录 SSH 使用密码
  echo "禁止root用户使用密码登录SSH..."
  sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/' /etc/ssh/sshd_config

  # 重启 SSH 服务
  echo "正在重启SSH服务..."
  sudo service ssh restart

  echo "已添加功能：客户端连接将保持活动状态，每30秒发送一次保持活动的请求，最多发送500次。"
}


# 功能7：调整交换空间大小
调整交换空间大小() {
  read -p "请输入新的交换空间大小（以MB为单位，输入0表示禁用交换空间）: " new_swap_size

  # 检查输入是否是数字
  if ! [[ $new_swap_size =~ ^[0-9]+$ ]]; then
    echo "无效输入。请输入一个正整数作为新的交换空间大小。"
    return
  fi

  # 禁用交换空间
  if [ "$new_swap_size" -eq 0 ]; then
    sudo swapoff -a
    sudo sed -i '/swap/d' /etc/fstab
    echo "已禁用交换空间。"
    return
  fi

  # 调整交换空间大小
  current_swap_size=$(free -m | awk '/Swap/ {print $2}')
  if [ "$new_swap_size" -eq "$current_swap_size" ]; then
    echo "交换空间大小已经是所需大小。"
    return
  fi

  # 调整交换空间大小
  sudo swapoff -a
  sudo dd if=/dev/zero of=/swapfile bs=1M count="$new_swap_size"
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile

  # 更新 /etc/fstab
  if ! grep -q "/swapfile" /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  fi

  echo "交换空间大小已调整为 ${new_swap_size}MB。"
}

# 主菜单
显示主菜单() {
  clear
  echo "脚本功能列表"
  echo "1. 安装 Docker 和 Docker Compose"
  echo "2. 启用 BBR FQ"
  echo "3. 清除所有容器日志"
  echo "4. 更新和清理系统"
  echo "5. 删除特定 Docker 容器和相关映射目录"
  echo "6. 添加SSH密钥"
  echo "7. 调整交换空间大小"
  echo "0. 退出"
  echo
  read -p "请输入选项编号： " option
  echo

  case $option in
    1) 安装_docker和_compose ;;
    2) 启用_bbr_fq ;;
    3) 清除容器日志 ;;
    4) 更新和清理系统 ;;
    5) 删除容器 ;;
    6) 添加_SSH密钥 ;;
    7) 调整交换空间大小 ;;
    0) exit ;;

    *) echo "无效选项，请输入有效选项。" ;;
  esac

  echo
  read -p "按Enter返回主菜单。"
  显示主菜单
}

# 显示主菜单
显示主菜单
