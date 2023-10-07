#!/bin/bash

# 提示用户选择操作
echo "请选择操作:"
echo "1. 打包文件"
echo "2. 解压文件"
read choice

# 打包文件
if [ "$choice" == "1" ]; then
  echo "请输入要打包的文件或目录的路径:"
  read source_path
  echo "请输入打包后的文件名:"
  read zip_filename
  echo "正在打包文件..."
  zip -r -q - "$source_path" | pv -p -s $(du -sb "$source_path" | awk '{print $1}') | gzip > "$zip_filename.zip"
  echo "文件已打包完成。"

# 解压文件
elif [ "$choice" == "2" ]; then
  echo "请输入要解压的ZIP文件的路径:"
  read zip_path
  echo "请输入解压后的目标文件夹路径:"
  read destination_folder
  echo "正在解压文件..."
  pv "$zip_path" | gunzip -c - | tar x -C "$destination_folder"
  echo "文件已解压完成。"

# 选择无效
else
  echo "无效的选择。请重新运行脚本并选择1或2。"
fi
