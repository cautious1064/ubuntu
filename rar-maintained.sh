#!/bin/bash

echo "RAR压缩和解压工具"

select choice in "压缩文件/文件夹" "解压RAR文件" "退出"; do
    case $choice in
        "压缩文件/文件夹")
            read -p "请输入要压缩的文件或文件夹路径: " filepath
            if [ ! -e "$filepath" ]; then
                echo "路径不存在"
                exit 1
            fi

            output_filename=$(basename "$filepath").rar
            rar a "$output_filename" "$filepath"
            echo "压缩完成"
            ;;
        "解压RAR文件")
            read -p "请输入要解压的RAR文件路径: " filepath
            if [ ! -e "$filepath" ]; then
                echo "路径不存在"
                exit 1
            fi

            # 提取目标路径
            target_dir=$(dirname "$filepath")
            unrar x "$filepath" "$target_dir"
            echo "解压完成"
            ;;
        "退出")
            break
            ;;
        *) 
            echo "无效选项"
            ;;
    esac
done
