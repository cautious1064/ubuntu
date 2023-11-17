#!/bin/bash

# 打印菜单供用户选择
echo "请选择操作:"
echo "1. 备份 Docker 容器和镜像"
echo "2. 恢复 Docker 容器和镜像"
echo "3. 备份 Docker 网络设置"
echo "4. 恢复 Docker 网络设置"
echo "5. 备份 Docker 数据卷"
echo "6. 恢复 Docker 数据卷"
read -p "输入选项 (1/2/3/4/5/6): " option

# 询问用户输入备份/恢复路径
read -p "请输入备份/恢复的路径: " path

# 备份Docker容器和镜像
backup_containers_images() {
  docker ps -aq | jq -r '.[]' | xargs docker save -o "$path/containers.tar"
  docker images -q | jq -r '.[]' | xargs docker save -o "$path/images.tar"
  echo "容器和镜像备份完成。"
}

# 恢复Docker容器和镜像
restore_containers_images() {
  docker load -i "$path/containers.tar"
  docker load -i "$path/images.tar"
  echo "容器和镜像恢复完成。"
}

# 备份Docker网络设置
backup_networks() {
  docker network ls -q | jq -r '.[]' | xargs docker network save -o "$path/networks.tar"
  echo "网络设置备份完成。"
}

# 恢复Docker网络设置
restore_networks() {
  docker network create -d bridge my_network
  docker network import "$path/networks.tar"
  echo "网络设置恢复完成。"
}

# 备份Docker数据卷
backup_volumes() {
  docker run --rm -v my_volume:/backup_data -v "$path:/backup" ubuntu tar czf /backup/volume_backup.tar.gz /backup_data
  echo "数据卷备份完成。"
}

# 恢复Docker数据卷
restore_volumes() {
  docker run --rm -v my_volume:/restore_data -v "$path:/restore" ubuntu tar xzf /restore/volume_backup.tar.gz -C /restore_data
  echo "数据卷恢复完成。"
}

case $option in
  1) backup_containers_images;;
  2) restore_containers_images;;
  3) backup_networks;;
  4) restore_networks;;
  5) backup_volumes;;
  6) restore_volumes;;
  *) echo "无效的选项";;
esac
