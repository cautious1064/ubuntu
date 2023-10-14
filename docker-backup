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
    if ! docker ps -q -f id=$CONTAINER_ID &>/dev/null; then
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
    docker inspect $CONTAINER_ID > "$METADATA_FILE"

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
    tar -xzvf "$BACKUP_PATH" -C $BACKUP_DIR

    # 提取快照和元数据文件
    SNAPSHOT_NAME=$(tar -tzf "$BACKUP_PATH" | grep '.tar' | head -n 1)
    METADATA_FILE=$(tar -tzf "$BACKUP_PATH" | grep '.json' | head -n 1)

    # 创建新容器
    docker run -d --name "$NEW_CONTAINER_NAME" -v /dev/null --rm "$SNAPSHOT_NAME"

    # 恢复容器元数据
    docker create --name temp-container --volume /temp-volume alpine /bin/sh
    docker cp "$BACKUP_DIR/$METADATA_FILE" temp-container:/metadata.json
    docker cp temp-container:/metadata.json "$NEW_CONTAINER_NAME:/metadata.json"
    docker rm -f temp-container

    echo "恢复完成：$NEW_CONTAINER_NAME"
}

# 主菜单
while true; do
    echo "1. 备份容器"
    echo "2. 恢复容器"
    echo "3. 退出"
    read -p "请选择操作: " choice
    case $choice in
        1)
            backup_container
            ;;
        2)
            restore_container
            ;;
        3)
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo "请选择有效选项"
            ;;
    esac
done
