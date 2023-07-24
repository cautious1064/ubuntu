#!/bin/bash

# 检查是否以 root 权限运行脚本
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本"
  exit 1
fi

# 检查是否为 Ubuntu 系统
if [ ! -f "/etc/os-release" ]; then
  echo "无法找到 /etc/os-release 文件，此脚本仅支持 Ubuntu 系统"
  exit 1
fi

# 获取当前 Ubuntu 版本信息
source /etc/os-release

echo "当前运行的 Ubuntu 版本为: $PRETTY_NAME"

# 检查是否为 LTS 版本
if [[ "$UBUNTU_CODENAME" == "bionic" ]]; then
  echo "当前运行的 Ubuntu 版本为 LTS 版本"
else
  echo "当前运行的 Ubuntu 版本不是 LTS 版本，不支持自动升级"
  exit 1
fi

read -p "是否要升级到新的 LTS 版本？(y/n): " choice

if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
  echo "取消升级操作"
  exit 0
fi

# 更新软件源并升级已安装的软件包
apt update
apt upgrade -y

# 安装升级工具
apt install -y update-manager-core

# 开始升级 Ubuntu 版本 (LTS 到 LTS)
do-release-upgrade

# 检查升级是否成功，可以根据实际情况进行处理
if [ $? -eq 0 ]; then
  echo "Ubuntu LTS 版本升级完成！"
else
  echo "Ubuntu 版本升级过程中发生错误，请检查日志以及终端输出，以便解决问题。"
fi