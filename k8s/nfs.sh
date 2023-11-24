#!/usr/bin/env bash
set -e

# 备份地址
BACKUP_DIR=/data/nfs

if [ -z "${1}" ]; then
  echo 'Args-1 Bucket Name';
  exit 1;
fi

if [ -z "${2}" ]; then
  echo 'Args-2 Cos Config';
  exit 1;
fi

# 压缩文件
day=$(date +"%Y_%m_%d")
tar -zcvf "${day}.tar.gz" "${BACKUP_DIR}"

# 上传文件到
backupFile="${day}.tar.gz"
./tencent_cos.sh "${backupFile}" "$1" "nfs/nfs-${day}.tar.gz" "$2"