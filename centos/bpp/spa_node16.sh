#!/usr/bin/env bash
set -e

# 工作目录
WORKING="${CI_PROJECT_DIR}"
PROJECT_ID="${CI_PROJECT_ID}"
PACKAGE_TYPE="${P_PACKAGE_TYPE^^}"
IMAGE_NAME="${P_IMAGE_NAME}"
# 脚本命令的前缀
SCRIPT_KEY="GL_BUILD_SCRIPT_"

echo "工作目录: ${WORKING}"
echo "项目ID: ${PROJECT_ID}"
echo "构建类型: ${PACKAGE_TYPE}"
echo "镜像: ${IMAGE_NAME}"



# 执行创建缓存目录
mkdir -p /opt/repository/"$PROJECT_ID"

# 读取需要执行的脚本
SCRIPT=$(curl -s 127.0.0.1:8080/pair/GL_BUILD_SCRIPT_MVN17 | jq -r '.data')
echo "$SCRIPT"

# 构建镜像
docker build -t "$IMAGE_NAME"