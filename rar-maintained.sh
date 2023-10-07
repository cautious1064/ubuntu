#!/bin/bash

# 菜单函数
show_menu() {
    echo "请选择一个操作:"
    echo "1. 压缩文件或文件夹为ZIP"
    echo "2. 解压缩ZIP文件"
    echo "3. 退出"
}

# 压缩函数
compress_files() {
    # 输入要压缩的文件或文件夹路径
    read -p "请输入要压缩的文件或文件夹路径: " source_path

    # 检查路径是否存在
    if [ ! -e "$source_path" ]; then
        echo "路径不存在，请重新输入."
        return
    fi

    # 获取源文件或文件夹的基本名称
    source_basename=$(basename "$source_path")

    # 创建UTF-8编码的ZIP压缩文件
    echo "正在创建UTF-8编码的ZIP压缩文件..."
    zip -r -O UTF-8 "$source_basename.zip" "$source_path"

    if [ $? -eq 0 ]; then
        echo "压缩完成。"
    else
        echo "压缩过程中出现错误，请检查输入和路径，然后重试。"
    fi
}

# 解压缩函数
extract_files() {
    # 输入要解压的ZIP文件路径
    read -p "请输入要解压的ZIP文件路径: " zip_path

    # 检查ZIP文件是否存在
    if [ ! -e "$zip_path" ]; then
        echo "ZIP文件不存在，请重新输入."
        return
    fi

    # 解压ZIP文件
    echo "正在解压ZIP文件..."
    unzip "$zip_path"

    if [ $? -eq 0 ]; then
        echo "解压完成。"
    else
        echo "解压过程中出现错误，请检查输入和路径，然后重试。"
    fi
}

# 主循环
while true; do
    show_menu
    read -p "请选择操作（1/2/3）: " choice

    case $choice in
    1)
        compress_files
        ;;
    2)
        extract_files
        ;;
    3)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效的选项，请重新选择。"
        ;;
    esac
done
