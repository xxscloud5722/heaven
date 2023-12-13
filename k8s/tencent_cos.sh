#!/bin/bash
set -e

# Time：2023-11-23
# Name: Lx

# =================================================================
# 腾讯云桶 COS
# https://cloud.tencent.com/document/product/436/71763
# 1. 关于配置 根据以上自己生成
# =================================================================



if [ -z "${1}" ]; then
  echo 'Args-1 localFile Path';
  exit 1;
fi

if [ -z "${2}" ]; then
  echo 'Args-2 Bucket Name';
  exit 1;
fi

if [ -z "${3}" ]; then
  echo 'Args-3 COS Path, Do not start with /';
  exit 1;
fi


if [ -z "${4}" ]; then
  echo 'Args-4 COS Config, refer to: https://cloud.tencent.com/document/product/436/71763';
  exit 1;
fi

LOCAL_FILE=$1
BUCKET=$2
COS_PATH=$3
CONFIG_PATH=$4

# 上传文件
day=$(date +"%Y_%m_%d")
./coscli sync "${LOCAL_FILE}" cos://"${BUCKET}/${day}/${COS_PATH}" -c "${CONFIG_PATH}"

# 有效的文件
if [ -z "$LOCAL_FILE" ]; then
  exit 1
fi
# 路径是否存在
if [ ! -e "$LOCAL_FILE" ]; then
  exit 1
fi
# 获取规范化的绝对路径
LOCAL_FILE=$(realpath "$LOCAL_FILE")
# 检查是一个文件
if [ -d "$LOCAL_FILE" ]; then
  exit 1
fi
# 删除文件
rm -rf "${LOCAL_FILE}"
