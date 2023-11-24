#!/usr/bin/env bash
set -e

# 备份地址
BACKUP_DIR=/data/atlassian/confluence_data/backups
COS_DIR=/opt

if [ -z "${1}" ]; then
  echo 'Args-1 Bucket Name';
  exit 1;
fi

if [ -z "${2}" ]; then
  echo 'Args-2 Cos Config';
  exit 1;
fi

cd "${BACKUP_DIR}"

# 扫描目录下文件是否超过50个文件
fileCount=$(find "${BACKUP_DIR}" -maxdepth 1 -type f | wc -l)
if [ "${fileCount}" -gt 50 ]; then
  echo "[Confluence] files in ${fileCount} is gt 50."
  echo "[Confluence] delete file."
else
  echo "[Confluence] files normal."
fi

# 上传文件到
backupFile=$(ls -t "${BACKUP_DIR}" | head -n 1)
day=$(date +"%Y_%m_%d")
if [[ ${backupFile} == *"${day}"* ]]; then
  echo "[Confluence] Backup file (${backupFile}) ready .."
  cd "${COS_DIR}"
  ./tencent_cos.sh "${BACKUP_DIR}/${backupFile}" "$1" "confluence/confluence-${day}.zip" "$2"
else
  echo "[Confluence] Backup file not ready !"
  exit 1
fi