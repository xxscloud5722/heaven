#!/bin/bash
set -e

# Time：2023-11-22
# Name: Judy

# 证书文件存放的路径
CONFIG_PATH="./configs"

# 检查命令文件是否存在
if [ "$(ls -A "${CONFIG_PATH}")" ]; then

  # 获取目录下的所有文件, 并按照文件名排序
  files=("${CONFIG_PATH}"/*)

  # 循环检查每个文件是否存在并执行相关操作
  for file in "${files[@]}"; do
    # 检查文件是否存在
    if [ -f "${file}" ]; then
      fileName=$(basename "${file}")
      fileName="${fileName%.*}"
      echo "[Run] Config: ${file} fileName: ${fileName}"

      # 执行脚本
      eval "$1"

      # 检查执行结果
      if [ $? -eq 0 ]; then
        # 输出脚本执行成功
        echo "[Run] '$1' execution successful!"
      else
        # 输出脚本执行失败
        echo "[Run] '$1' execution failed!"
      fi

    else
      echo "[Scan] $file does not exist"
      # 如果文件不存在，退出脚本
      exit 1
    fi
  done

  # 所有配置都存在，执行完所有操作
  echo -e "\e[1;32mComplete all operations !\e[0m"
else
  echo "[Scan] The directory is empty"
  exit 1
fi
