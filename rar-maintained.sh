#!/bin/bash

# 安装 unrar 软件包
sudo apt-get install -y unrar

function extract_rar {
  # 检查参数是否为空
  if [[ -z $1 || -z $2 ]]; then
    echo "未提供RAR文件或目标文件夹"
    exit 1
  fi

  # 解压缩RAR文件到目标文件夹
  unrar x "$1" "$2"

  # 检查解压缩是否成功
  if [[ $? -eq 0 ]]; then
    echo "解压缩完成"
  else
    echo "解压缩失败"
  fi
}

function compress_rar {
  # 检查参数是否为空
  if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "未提供源文件夹、是否加密和RAR文件名称"
    exit 1
  fi

  SOURCE="$1"
  ENCRYPTED="$2"
  RAR_FILE="$3"

  # 获取文件夹所在目录
  SOURCE_DIR=$(dirname "$SOURCE")

  # 构建RAR命令
  RAR_COMMAND="rar a"

  # 添加加密选项到RAR命令
  if [[ $ENCRYPTED == "是" ]]; then
    echo -n "请输入压缩文件的密码: "
    read -r -s PASSWORD
    RAR_COMMAND+=" -p${PASSWORD}"
  fi

  # 添加压缩文件夹和RAR文件路径到RAR命令
  RAR_COMMAND+=" \"$SOURCE_DIR/$RAR_FILE\" \"$SOURCE\""

  # 切换到文件所在目录
  cd "$SOURCE_DIR" || exit 1

  # 压缩文件夹为RAR文件
  eval "$RAR_COMMAND"

  # 检查压缩是否成功
  if [[ $? -eq 0 ]]; then
    echo "压缩完成"
  else
    echo "压缩失败"
  fi
}

# 检查参数数量
if [[ $# -eq 0 ]]; then
  echo "未提供操作类型和必要参数"
  exit 1
fi

# 获取操作类型
ACTION="$1"

# 根据选择的操作类型执行相应的函数
if [[ $ACTION == "extract" ]]; then
  # 提取RAR文件
  extract_rar "$2" "$3"
elif [[ $ACTION == "compress" ]]; then
  # 压缩文件夹为RAR文件
  compress_rar "$2" "$3" "$4"
else
  echo "无效的操作类型"
  exit 1
fi
