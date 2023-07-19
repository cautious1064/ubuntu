#!/bin/bash

# 安装 unrar 和 zenity 软件包
sudo apt-get update
sudo apt-get install unrar zenity -y

function extract_rar {
  # 弹出对话框让用户选择RAR文件
  RAR_FILE=$(zenity --file-selection --title="选择RAR文件" --file-filter="RAR 文件 | *.rar" --file-filter="所有文件 | *")

  # 检查用户是否选择了RAR文件
  if [[ -z $RAR_FILE ]]; then
    zenity --error --text="未选择RAR文件"
    exit 1
  fi

  # 弹出对话框让用户选择解压缩目标文件夹
  DESTINATION=$(zenity --file-selection --title="选择解压缩目标文件夹" --directory)

  # 检查用户是否选择了目标文件夹
  if [[ -z $DESTINATION ]]; then
    zenity --error --text="未选择解压缩目标文件夹"
    exit 1
  fi

  # 解压缩RAR文件到目标文件夹
  unrar x "$RAR_FILE" "$DESTINATION"

  # 检查解压缩是否成功
  if [[ $? -eq 0 ]]; then
    zenity --info --text="解压缩完成"
  else
    zenity --error --text="解压缩失败"
  fi
}

function compress_rar {
  # 弹出对话框让用户选择要压缩的文件夹
  SOURCE=$(zenity --file-selection --title="选择要压缩的文件夹" --directory)

  # 检查用户是否选择了文件夹
  if [[ -z $SOURCE ]]; then
    zenity --error --text="未选择要压缩的文件夹"
    exit 1
  fi

  # 获取文件夹所在目录
  SOURCE_DIR=$(dirname "$SOURCE")

  # 弹出对话框让用户选择是否加密
  ENCRYPTED=$(zenity --list --title="选择是否加密" --text="是否加密压缩文件?" --radiolist --column="" --column="选项" FALSE "否" TRUE "是")

  # 检查用户是否选择了加密选项
  if [[ -z $ENCRYPTED ]]; then
    zenity --error --text="未选择加密选项"
    exit 1
  fi

  # 弹出对话框让用户选择是否分卷
  SPLIT=$(zenity --list --title="选择是否分卷" --text="是否将压缩文件分卷?" --radiolist --column="" --column="选项" FALSE "否" TRUE "是")

  # 检查用户是否选择了分卷选项
  if [[ -z $SPLIT ]]; then
    zenity --error --text="未选择分卷选项"
    exit 1
  fi

  # 弹出对话框让用户选择压缩后的RAR文件名称
  RAR_FILE=$(zenity --entry --title="输入压缩后的RAR文件名称" --text="请输入压缩后的RAR文件名称" --entry-text "archive.rar")

  # 检查用户是否输入了RAR文件名称
  if [[ -z $RAR_FILE ]]; then
    zenity --error --text="未输入压缩后的RAR文件名称"
    exit 1
  fi

  # 构建RAR命令
  RAR_COMMAND="rar a"

  # 添加加密选项到RAR命令
  if [[ $ENCRYPTED == "是" ]]; then
    PASSWORD=$(zenity --password --title="输入压缩文件密码" --text="请输入压缩文件的密码")
    RAR_COMMAND+=" -p${PASSWORD}"
  fi

  # 添加分卷选项到RAR命令
  if [[ $SPLIT == "是" ]]; then
    VOLUME_SIZE=$(zenity --entry --title="输入分卷大小" --text="请输入分卷的大小（以字节为单位）")
    RAR_COMMAND+=" -v${VOLUME_SIZE}"
  fi

  # 添加压缩文件夹和RAR文件路径到RAR命令
  RAR_COMMAND+=" \"$SOURCE_DIR/$RAR_FILE\" \"$SOURCE\""

  # 切换到文件所在目录
  cd "$SOURCE_DIR" || exit 1

  # 压缩文件夹为RAR文件
  eval "$RAR_COMMAND"

  # 检查压缩是否成功
  if [[ $? -eq 0 ]]; then
    zenity --info --text="压缩完成"
  else
    zenity --error --text="压缩失败"
  fi
}

# 弹出对话框让用户选择操作类型
ACTION=$(zenity --list --title="选择操作类型" --text="请选择要执行的操作" --radiolist --column="" --column="操作" FALSE "解压缩RAR文件" FALSE "压缩文件夹为RAR文件")

# 检查用户是否选择了操作类型
if [[ -z $ACTION ]]; then
  zenity --error --text="未选择操作类型"
  exit 1
fi

# 根据选择的操作类型执行相应的函数
if [[ $ACTION == "解压缩RAR文件" ]]; then
  extract_rar
elif [[ $ACTION == "压缩文件夹为RAR文件" ]]; then
  compress_rar
fi
