#!/bin/bash

# 函数：删除容器和相关映射目录
delete_container() {
  # 提示用户输入容器ID
  echo "请输入要删除的容器ID:"
  read container_id

  # 检查容器是否存在
  if docker ps -a --format "{{.ID}}" | grep -q "$container_id"; then
    # 获取相关映射目录
    mount_dirs=()
    while IFS= read -r mount_dir; do
      if [ -d "$mount_dir" ]; then
        mount_dirs+=("$mount_dir")
      fi
    done < <(docker container inspect "$container_id" --format='{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}')

    # 停止容器
    docker stop "$container_id"

    # 删除容器
    docker rm "$container_id"

    # 删除相关映射目录
    for mount_dir in "${mount_dirs[@]}"; do
      echo "删除目录: $mount_dir"
      rm -rf "$mount_dir"
    done

    echo "容器和相关映射目录已成功删除。"
  else
    echo "容器ID不存在。请提供有效的容器ID。"
  fi
}

# 函数：清空所有容器日志
clear_container_logs() {
  # 获取所有容器ID
  container_ids=$(docker ps -aq)

  # 遍历每个容器ID并清除日志
  for container_id in $container_ids; do
    # 获取容器的日志路径
    log_path=$(docker inspect --format='{{.LogPath}}' "$container_id")

    # 检查日志路径是否存在
    if [ -z "$log_path" ]; then
      echo "无法获取容器 $container_id 的日志路径！跳过该容器。"
      continue
    fi

    # 清空日志文件内容
    truncate -s 0 "$log_path"

    echo "容器 $container_id 的日志已成功清除！"
  done
}

# 函数：系统更新清理
system_cleanup() {
  # 更新系统
  echo "正在更新系统..."
  apt update && apt upgrade -y

  # 清理系统垃圾
  echo "正在清理垃圾..."
  apt autoclean
  apt autoremove -y

  # 清理日志文件
  echo "正在清理日志文件..."
  find /var/log -type f -delete

  # 清理备份
  backup_directory="/path/to/backup"  # 设置备份目录的路径
  echo "正在清理备份文件/目录 $backup_directory..."
  rm -rf "$backup_directory"

  echo "系统更新、垃圾清理、日志清理和备份清理完成！"
}

# 主菜单
while true; do
  echo "请选择要执行的操作:"
  echo "1. 删除容器和相关映射目录"
  echo "2. 清空所有容器日志"
  echo "3. 系统更新清理"
  echo "4. 退出"

  read choice

  case $choice in
    1)
      delete_container
      ;;
    2)
      clear_container_logs
      ;;
    3)
      system_cleanup
      ;;
    4)
      echo "退出脚本。"
      break
      ;;
    *)
      echo "无效的选项，请重新选择。"
      ;;
  esac

  echo
done
