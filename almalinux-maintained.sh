#!/bin/bash

# 函数：更新系统
function update_system() {
  echo "正在更新系统..."
  sudo dnf update -y
  echo "系统更新完成！"
  sleep 2
}

# 函数：安装 Docker
function install_docker() {
  echo "正在安装 Docker..."
  sudo dnf install -y dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker
  sudo systemctl enable docker
  echo "Docker 安装完成！"
  sleep 2
}

# 函数：安装 Docker Compose
function install_docker_compose() {
  echo "正在安装 Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose 安装完成！"
  sleep 2
}

# 主菜单
function show_menu() {
  clear
  echo "====================="
  echo "  AlmaLinux 工具脚本"
  echo "====================="
  echo "1. 更新系统"
  echo "2. 安装 Docker"
  echo "3. 安装 Docker Compose"
  echo "4. 退出"
  echo "====================="
}

# 执行选项
function execute_option() {
  local choice
  read -p "请输入选项号码: " choice
  case $choice in
    1)
      update_system
      ;;
    2)
      install_docker
      ;;
    3)
      install_docker_compose
      ;;
    4)
      exit 0
      ;;
    *)
      echo "无效的选项，请重试！"
      sleep 2
      ;;
  esac
}

# 主循环
while true
do
  show_menu
  execute_option
done
