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
  zip -r "$zip_filename.zip" "$source_path"
  echo "文件已打包完成。"

# 解压文件
elif [ "$choice" == "2" ]; then
  echo "请输入要解压的ZIP文件的路径:"
  read zip_path
  echo "请输入解压后的目标文件夹路径:"
  read destination_folder
  unzip "$zip_path" -d "$destination_folder"
  echo "文件已解压完成。"

# 选择无效
else
  echo "无效的选择。请重新运行脚本并选择1或2。"
fi
