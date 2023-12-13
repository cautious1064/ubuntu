#!/bin/sh

# 功能1：安装 Docker 和 Docker Compose
安装_docker和_compose() {
  echo "正在更新系统软件包..."
  apk update
  echo "正在安装 Docker Engine..."
  apk add docker
  echo "正在安装 Docker Compose..."
  apk add docker-compose
  apk add jq

  if [ -x "$(command -v docker)" ] && [ -x "$(command -v docker-compose)" ]; then
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
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p

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
  find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "容器日志已清除！"
}

# 功能4：更新和清理系统
更新和清理系统() {
  echo "正在更新软件包和基本工具..."
  apk update
  apk upgrade
  apk add curl sudo neofetch vim jq
  echo "软件包更新完成！"

  echo "正在清理系统..."
  apk clean
  rm -rf /var/cache/apk/*
  echo "系统清理完成！"

  echo "正在清理日志文件..."
  find /var/log -type f -delete
  echo "日志文件清理完成！"

  backup_directory="/path/to/backup"  # 将路径更改为实际的备份目录路径
  echo "正在清理备份文件/目录..."
  if [ -d "$backup_directory" ]; then
    rm -rf "$backup_directory"
    echo "备份文件/目录清理完成！"
  else
    echo "备份目录 $backup_directory 不存在。"
  fi

  echo "正在删除未使用的内核..."
  apk del $(apk info -q | grep '^rc') -y

  echo "正在清理缓存文件..."
  rm -rf /var/cache

  echo "系统更新、垃圾清理、日志清理、备份清理、未使用内核清理和缓存清理完成！"
}

# 功能5：删除特定 Docker 容器和相关映射目录
删除容器() {
  echo "请输入要删除的容器的ID： "
  read container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  fi

  # 获取容器的映射目录
  container_info=$(docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "无法检索容器的映射目录信息。"
    return
  fi

  # 解析容器的映射目录路径
  directories=($(echo "$container_info" | jq -r '.[].Source'))

  if [ ${#directories[@]} -eq 0 ]; then
    echo "容器没有映射目录。正在删除容器..."
    docker stop "$container_id"
    docker rm "$container_id"
    echo "容器 $container_id 已删除！"
  else
    echo "正在停止和删除容器 $container_id..."
    docker stop "$container_id"
    docker rm "$container_id"
    echo "容器 $container_id 已删除！"

    # 删除容器的映射目录
    for directory in "${directories[@]}"; do
      if [ -d "$directory" ]; then
        echo "正在删除映射目录 $directory..."
        rm -rf "$directory"
        echo "映射目录 $directory 已删除！"
      fi
    done
  fi

  echo "垃圾清理..."
  apk clean
  rm -rf /var/cache/apk/*
  echo "垃圾清理完成！"

  echo "正在清理日志文件..."
  find /var/log -type f -delete
  echo "日志文件清理完成！"

  echo "容器和相关映射目录已删除！"
}

# 功能6：添加SSH密钥
添加_SSH密钥() {
  echo "正在下载密钥文件..."
  curl -o cc-ikey -L web.cloudc.one/sh/key

  if [ ! -f "cc-ikey" ]; then
    echo "无法下载密钥文件。请检查网络连接和URL是否有效。"
    return
  fi

  # 运行 cc-ikey 脚本
  echo "正在运行cc-ikey脚本..."
  sh cc-ikey BShaL3Rw75i2

  if [ $? -ne 0 ]; then
    echo "cc-ikey脚本运行失败。请检查密钥文件和相关配置。"
    return
  fi

  # 配置密钥登录
  mkdir -p ~/.ssh
  cp cc-ikey ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  echo "IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config

  echo "密钥登录已配置完成。您可以使用密钥登录到服务器。"

  # 允许 root 用户登录 SSH
  echo "允许root用户登录SSH..."
  sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

  # 重启 SSH 服务
  echo "正在重启SSH服务..."
  service ssh restart

  echo "已添加功能：客户端连接将保持活动状态，每 30 秒发送一次保持活动的请求，最多发送 500 次。"
}

# 功能7：调整交换空间大小
调整交换空间大小() {
  echo "请输入新的交换空间大小（以MB为单位，输入0表示禁用交换空间）: "
  read new_swap_size

  # 检查输入是否是数字
  if ! expr "$new_swap_size" : '[0-9]\+$' > /dev/null; then
    echo "无效输入。请输入一个正整数作为新的交换空间大小。"
    return
  fi

  # 禁用交换空间
  if [ "$new_swap_size" -eq 0 ]; then
    swapoff -a
    sed -i '/swap/d' /etc/fstab
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
  swapoff -a
  dd if=/dev/zero of=/swapfile bs=1M count="$new_swap_size"
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

  # 更新 /etc/fstab
  if ! grep -q "/swapfile" /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
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
  echo "请输入选项编号： "
  read option
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
  echo "按Enter返回主菜单。"
  显示主菜单
}

# 显示主菜单
显示主菜单
