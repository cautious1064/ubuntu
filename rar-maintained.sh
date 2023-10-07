#!/bin/bash

# 检查rar是否已经安装，如果没有安装就安装rar
if ! command -v rar &> /dev/null; then
    echo "安装rar..."
    sudo apt-get update
    sudo apt-get install rar
    if [ $? -ne 0 ]; then
        echo "安装rar失败，请手动安装rar后再运行此脚本。"
        exit 1
    fi
else
    echo "rar已经安装."
fi

# 菜单函数
show_menu() {
    echo "请选择一个操作:"
    echo "1. 压缩文件或文件夹"
    echo "2. 解压缩文件"
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

    # 输入压缩密码
    read -s -p "请输入压缩密码: " password
    echo

    # 输入目标路径
    read -p "请输入目标路径: " target_path

    # 自动计算分卷大小，默认单位为GB
    read -p "请输入分卷大小（默认单位为GB，直接回车使用默认值）: " volume_size
    volume_size=${volume_size:-5}  # 默认值为5GB

    # 创建RAR压缩文件
    echo "正在创建RAR压缩文件..."
    rar a -p"$password" -v${volume_size}g "$target_path/compressed.rar" "$source_path"

    if [ $? -eq 0 ]; then
        echo "压缩完成。"
    else
        echo "压缩过程中出现错误，请检查输入和路径，然后重试。"
    fi
}

# 解压缩函数
extract_files() {
    # 输入要解压的文件路径
    read -p "请输入要解压的RAR文件路径: " rar_path

    # 检查RAR文件是否存在
    if [ ! -e "$rar_path" ]; then
        echo "RAR文件不存在，请重新输入."
        return
    fi

    # 输入解压密码
    read -s -p "请输入解压密码: " password
    echo

    # 输入目标路径
    read -p "请输入解压到的目标路径: " target_path

    # 解压RAR文件
    echo "正在解压RAR文件..."
    rar x -p"$password" "$rar_path" "$target_path"

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
