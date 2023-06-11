#!/bin/bash

# 删除容器和相关映射目录
delete_container() {
  read -p "请输入要删除的容器ID: " container_id

  echo "系统更新完成！"

  echo "正在清理垃圾..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "正在清理日志文件..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  backup_directory="/path/to/backup"  # 设置备份目录的路径
  echo "正在清理备份文件/目录 $backup_directory..."
  sudo rm -rf "$backup_directory"
  echo "备份文件/目录清理完成！"

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
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  # 输出Docker和Docker Compose版本
  docker --version
  docker-compose --version
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
    echo "3. 安装Docker和Docker Compose"
    echo "4. 开启BBR FQ"
    echo "5. 返回主菜单"

    read -r choice

    case $choice in
      1)
        delete_container
        ;;
      2)
        clear_container_logs
        ;;
      3)
        install_docker_and_compose
        ;;
      4)
        enable_bbr_fq
        ;;
      5)
        echo "返回主菜单。"
        break
        ;;
      *)
        echo "无效的选项，请重新选择。"
        ;;
    esac

    echo
  done
}

# 主菜单
while true; do
  echo "请选择要执行的操作:"
  echo "1. 日常维护"
  echo "2. 面板安装"
  echo "3. 退出"

  read -r choice

  case $choice in
    1)
      maintenance_menu
      ;;
    2)
      install_aapanel
      ;;
    3)
      echo "退出脚本。"
      break
      ;;
    *)
      echo "无效的选项，请重新选择。"
      ;;
  esac

  echo
done
