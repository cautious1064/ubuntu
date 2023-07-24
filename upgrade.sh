#!/bin/bash

# 提示用户备份数据
echo "请在执行升级前备份重要数据！"
read -p "按回车键继续升级，或按 Ctrl+C 取消："

# 更新软件包列表
sudo apt update

# 更新已安装的软件包
sudo apt upgrade -y

# 执行系统升级
sudo do-release-upgrade

# 如果升级完成后需要重启，提示用户重启
echo "系统升级已完成！"
read -p "按回车键重启计算机，或按 Ctrl+C 取消重启："
sudo reboot
