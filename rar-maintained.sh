#!/bin/bash

# 检查rar是否已经安装，如果没有安装就安装rar
if ! command -v rar &> /dev/null
then
    echo "安装rar..."
    sudo apt-get update
    sudo apt-get install rar
else
    echo "rar已经安装."
fi

# 输入要压缩的文件或文件夹路径
read -p "请输入要压缩的文件或文件夹路径: " source_path

# 检查路径是否存在
if [ ! -e "$source_path" ]
then
    echo "路径不存在，请重新输入."
    exit 1
fi

# 输入压缩密码
read -s -p "请输入压缩密码: " password
echo

# 输入目标路径
read -p "请输入目标路径: " target_path

# 创建RAR压缩文件
echo "正在创建RAR压缩文件..."
rar a -p"$password" -v5g "$target_path/compressed.rar" "$source_path"

echo "压缩完成。"
