#!/bin/bash

# 检查当前用户是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   echo "请以 root 用户身份运行此脚本。"
   exit 1
fi

# 检测系统类型
if [ -f /etc/debian_version ]; then
   # Debian 系统
   apt update
   apt upgrade -y
   apt dist-upgrade -y
   apt autoremove -y
   apt autoclean
elif [ -f /etc/lsb-release ]; then
   # Ubuntu 系统
   apt update
   apt upgrade -y
   do-release-upgrade -f DistUpgradeViewNonInteractive
else
   echo "无法确定系统类型。"
   exit 1
fi

# 重启系统
shutdown -r now
