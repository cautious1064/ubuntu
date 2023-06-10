#!/bin/bash

# 函数：删除容器和相关映射目录
delete_container() {
  echo "请输入要删除的容器ID:"
  read container_id

  if docker ps -a --format "{{.ID}}" | grep -q "$container_id"; then
    mount_dirs=()
    while IFS= read -r mount_dir; do
      if [ -d "$mount_dir" ]; then
        mount_dirs+=("$mount_dir")
      fi
    done < <(docker container inspect "$container_id" --format='{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}')

    docker stop "$container_id"
    docker rm "$container_id"

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
  container_ids=$(docker ps -aq)

  for container_id in $container_ids; do
    log_path=$(docker inspect --format='{{.LogPath}}' "$container_id")

    if [ -z "$log_path" ]; then
      echo "无法获取容器 $container_id 的日志路径！跳过该容器。"
      continue
    fi

    truncate -s 0 "$log_path"

    echo "容器 $container_id 的日志已成功清除！"
  done
}

# 函数：系统更新清理
system_cleanup() {
  echo "正在更新系统..."
  apt update && apt upgrade -y

  echo "正在清理垃圾..."
  apt autoclean
  apt autoremove -y

  echo "正在清理日志文件..."
  find /var/log -type f -delete

  backup_directory="/path/to/backup"  # 设置备份目录的路径
  echo "正在清理备份文件/目录 $backup_directory..."
  rm -rf "$backup_directory"

  echo "系统更新、垃圾清理、日志清理和备份清理完成！"
}

# 函数：安装aapanel
install_aapanel() {
  echo "正在下载并执行aapanel安装脚本..."
  wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel

  echo "aapanel安装完成！"
}

# 函数：安装casaos
install_casaos() {
  echo "正在安装casaos..."
  curl -fsSL https://get.casaos.io | sudo bash

  echo "casaos安装完成！"
}

# 日常维护子功能菜单
maintenance_menu() {
  while true; do
    echo "请选择要执行的日常维护操作:"
    echo "1. 删除容器和相关映射目录"
    echo "2. 清空所有容器日志"
    echo "3. 系统更新清理"
    echo "4. 返回主菜单"

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
        echo "返回主菜单。"
        break
        ;;
      *)
        echo "无效的选项，请重新选择。"
        ;;
    esac

    echo
  done
}

# 面板安装子功能菜单
panel_installation_menu() {
  while true; do
    echo "请选择要执行的面板安装操作:"
    echo "1. 安装aapanel"
    echo "2. 安装casaos"
    echo "3. 返回主菜单"

    read choice

    case $choice in
      1)
        install_aapanel
        ;;
      2)
        install_casaos
        ;;
      3)
        echo "返回主菜单。"
        break
        ;;
      *)
        echo "无效的选项，请重新选择。"
        ;;
    esac

    echo
  done
}

# 主菜单
while true; do
  echo "请选择要执行的操作:"
  echo "1. 日常维护"
  echo "2. 面板安装"
  echo "3. 退出"

  read choice

  case $choice in
    1)
      maintenance_menu
      ;;
    2)
      panel_installation_menu
      ;;
    3)
      echo "退出脚本。"
      break
      ;;
    *)
      echo "无效的选项，请重新选择。"
      ;;
  esac

  echo
done

