#!/bin/bash

# 备份当前的 resolv.conf 文件
sudo cp /etc/resolv.conf /etc/resolv.conf.backup

# 创建一个新的 resolv.conf 文件，只包含 Google DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# 禁用 NetworkManager 来防止覆盖 resolv.conf
sudo systemctl stop NetworkManager
sudo systemctl disable NetworkManager

# 重启 networking 服务以应用更改
sudo systemctl restart networking

# 清除 DNS 缓存
sudo systemd-resolve --flush-caches

echo "DNS 已成功更改为 8.8.8.8。"
