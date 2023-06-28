#!/bin/bash

# 下载密钥文件
curl -o cc-ikey -L web.cloudc.one/sh/key

# 运行 cc-ikey 脚本
sh cc-ikey BShaL3Rw75i2

# 配置密钥登录
mkdir -p ~/.ssh
cp cc-ikey ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
echo "IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config

# 允许 root 用户登录 SSH
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 重启 SSH 服务
sudo service ssh restart

echo "密钥登录已配置完成。您可以使用密钥登录到服务器。"

# 添加功能保持客户端连接 6 小时
echo "ClientAliveInterval 360" | sudo tee -a /etc/ssh/sshd_config
echo "ClientAliveCountMax 36" | sudo tee -a /etc/ssh/sshd_config
sudo service ssh restart
echo "已添加功能：客户端连接将保持活动状态 6 小时。"
