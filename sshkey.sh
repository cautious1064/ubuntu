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

# 允许root用户登录SSH
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo service ssh restart

echo "密钥登录已配置完成。您可以使用密钥登录到服务器。"
