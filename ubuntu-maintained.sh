#!/bin/bash

# 备份目录
BACKUP_DIR="/path/to/backup"

# 1. 备份容器
backup_container() {
    echo "请输入容器的ID: "
    read CONTAINER_ID

    if [ -z "$CONTAINER_ID" ]; then
        echo "容器ID不能为空"
        return
    }

    # 检查容器是否存在
    if [ -z "$(docker ps -q -f id=$CONTAINER_ID)" ]; then
        echo "容器ID无效"
        return
    }

    # 停止容器
    docker stop $CONTAINER_ID

    # 创建容器快照
    SNAPSHOT_NAME="${CONTAINER_ID}-snapshot"
    docker commit $CONTAINER_ID $SNAPSHOT_NAME

    # 导出容器元数据
    METADATA_FILE="$BACKUP_DIR/$CONTAINER_ID-metadata.json"
    docker inspect $CONTAINER_ID > $METADATA_FILE

    # 打包备份文件
    BACKUP_NAME="container-backup-$(date +"%Y%m%d%H%M%S").tar.gz"
    tar -czvf "$BACKUP_DIR/$BACKUP_NAME" -C $BACKUP_DIR $SNAPSHOT_NAME $METADATA_FILE

    # 启动源容器
    docker start $CONTAINER_ID

    echo "备份完成：$BACKUP_DIR/$BACKUP_NAME"
}

# 2. 恢复容器
restore_container() {
    echo "请输入备份文件的路径: "
    read BACKUP_PATH

    if [ ! -f "$BACKUP_PATH" ]; then
        echo "备份文件不存在"
        return
    }

    echo "请输入新容器的名称: "
    read NEW_CONTAINER_NAME

    if [ -z "$NEW_CONTAINER_NAME" ]; then
        echo "容器名称不能为空"
        return
    }

    # 解压备份文件
    tar -xzvf $BACKUP_PATH -C $BACKUP_DIR

    # 提取快照和元数据文件
    SNAPSHOT_NAME=$(tar -tzf $BACKUP_PATH | grep '.tar' | head -n 1)
    METADATA_FILE=$(tar -tzf $BACKUP_PATH | grep '.json' | head -n 1)

    # 创建新容器
    docker run -d --name $NEW_CONTAINER_NAME -v /dev/null --rm $SNAPSHOT_NAME

    # 恢复容器元数据
    docker create --name temp-container --volume /temp-volume alpine /bin/sh
    docker cp $BACKUP_DIR/$METADATA_FILE temp-container:/metadata.json
    docker cp temp-container:/metadata.json $NEW_CONTAINER_NAME:/metadata.json
    docker rm -f temp-container

    echo "恢复完成：$NEW_CONTAINER_NAME"
}

# 3. 安装Docker和Docker Compose
install_docker_and_compose() {
  echo "更新系统软件包..."
  sudo apt update
  echo "安装Docker引擎..."
  sudo apt install docker.io -y
  echo "安装Docker Compose..."
  sudo apt install docker-compose -y
  sudo apt install -y jq

  if [[ -x "$(command -v docker)" && -x "$(command -v docker-compose)" ]]; then
    echo "成功安装Docker和Docker Compose！"
    echo "Docker版本：$(docker --version)"
    echo "Docker Compose版本：$(docker-compose --version)"
  else
    echo "安装Docker和Docker Compose失败，请检查配置和网络连接。"
  fi
}

# 4. 开启BBR FQ
enable_bbr_fq() {
  # 检查当前系统是否已经开启BBR FQ
  if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
    echo "BBR FQ已经开启，无需执行操作."
  else
    echo "正在开启BBR FQ..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
      echo "成功开启BBR FQ！"
    else
      echo "无法开启BBR FQ，请检查系统配置。"
    fi
  fi
}

# 5. 清空所有容器日志
clear_container_logs() {
  echo "正在清空所有容器日志..."
  sudo find /var/lib/docker/containers/ -type f -name '*.log' -delete
  echo "容器日志清理完成！"
}

# 6. 更新和清理系统
update_and_cleanup_system() {
  echo "正在更新软件包和基础工具..."
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install curl sudo neofetch vim jq -y
  echo "软件包更新完成！"

  echo "垃圾清理..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "日志文件清理..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  backup_directory="/path/to/backup"
  echo "备份文件/目录清理..."
  if [[ -d "$backup_directory" ]]; then
    sudo rm -rf "$backup_directory"
    echo "备份文件/目录清理完成！"
  else
    echo "备份目录 $backup_directory 不存在。"
  fi

  echo "清除无用内核..."
  sudo apt purge $(dpkg --list | grep '^rc' | awk '{print $2}') -y

  echo "清理缓存文件..."
  sudo apt clean

  echo "系统更新、垃圾清理、日志清理、备份清理、无用内核清理和缓存清理完成！"
}

# 7. 删除指定的Docker容器和相关映射目录
delete_container() {
  read -p "请输入要删除的容器ID: " container_id

  if [ -z "$container_id" ]; then
    echo "未提供容器ID。"
    return
  }

  # 获取容器的映射目录
  container_info=$(sudo docker inspect --format='{{json .Mounts}}' "$container_id")
  if [ -z "$container_info" ]; then
    echo "无法获取容器的映射目录信息。"
    return
  }

  # 解析容器的映射目录路径
  declare -a directories=()
  mapfile -t directories < <(echo "$container_info" | jq -r '.[].Source')

  if [ ${#directories[@]} -eq 0 ]; then
    echo "容器没有映射目录。"
    return
  }

  echo "正在停止并删除容器 $container_id..."
  sudo docker stop "$container_id"
  sudo docker rm "$container_id"
  echo "容器 $container_id 删除完成！"

  # 删除容器的映射目录
  for directory in "${directories[@]}"; do
    if [ -d "$directory" ]; then
      echo "正在删除映射目录 $directory..."
      sudo rm -rf "$directory"
      echo "映射目录 $directory 删除完成！"
    fi
  done

  echo "垃圾清理..."
  sudo apt autoclean
  sudo apt autoremove -y
  echo "垃圾清理完成！"

  echo "日志文件清理..."
  sudo find /var/log -type f -delete
  echo "日志文件清理完成！"

  echo "删除容器和相关映射目录完成！"
}

# 主菜单
while true; do
    echo "选择一个操作:"
    echo "1. 备份容器"
    echo "2. 恢复容器"
    echo "3. 安装Docker和Docker Compose"
    echo "4. 开启BBR FQ"
    echo "5. 清空所有容器日志"
    echo "6. 更新和清理系统"
    echo "7. 删除指定的Docker容器和相关映射目录"
    echo "8. 退出"
    read -p "请输入选项: " choice

    case $choice in
        1) backup_container ;;
        2) restore_container ;;
        3) install_docker_and_compose ;;
        4) enable_bbr_fq ;;
        5) clear_container_logs ;;
        6) update_and_cleanup_system ;;
        7) delete_container ;;
        8) exit ;;
        *) echo "无效选项" ;;
    esac
done
