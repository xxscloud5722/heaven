#!/usr/bin/env bash
set -e

echo -e "\e[32m================================================================\e[0m"
echo -e "\e[32mVersion: 1.0.0\e[0m"
echo -e "\e[32mAuthor: LX\e[0m"
echo -e "\e[32mArgs\e[0m"
echo -e "\e[32m  - 1 (Optional): Path Config\e[0m"
echo -e "\e[32m  - 2 (Optional): Mode: ('DEFAULT' or 'JOB')\e[0m"
echo -e "\e[32m  - 3 (Optional): Only valid if MODE is JOB, specify the output file name\e[0m"
echo -e "\e[32m================================================================\e[0m"


if [ -z "${1}" ]; then
  echo "输入配置文件地址 (~/.kube/config)";
  # shellcheck disable=SC2162
  read configPath
else
  configPath="${1}"
fi
if [ -z "${configPath}" ]; then
  configPath="$HOME/.kube/config"
  echo -e "\e[34mPath: $configPath\e[0m"
else
  echo -e "\e[34mPath: $configPath\e[0m"
fi

backupMode="DEFAULT"
if [ "${2^^}" == "JOB" ]; then
  backupMode="JOB"
fi

if [ "${backupMode^^}" != "JOB" ]; then
  echo "是否压缩存储? [Y/n] (默认: N)";
  # shellcheck disable=SC2162
  read compress
  if [ -z "${compress}" ]; then
    compress='N'
  fi
else
  compress='Y'
fi

if [ "${compress^^}" == "Y" ]; then
  echo -e "\e[34m启用压缩存储\e[0m"
else
  echo -e "\e[34m禁用压缩存储\e[0m"
fi




# ============================================================
# 执行备份命令
backupDir="./k8s_backup"
if [ -d "$backupDir" ]; then
  if [ "${backupMode^^}" != "JOB" ]; then
    echo -e "\e[93m备份目录已存在, 回车确认删除 (CTRL + C 结束执行)\e[0m"
    # shellcheck disable=SC2162
    read
  fi
  uuid=$(uuidgen)
  mv -f "${backupDir}" "/tmp/${uuid}"
fi

mkdir -p "$backupDir"

# 获取所有命名空间
namespaces=$(kubectl --kubeconfig="${configPath}" get namespaces -o jsonpath='{.items[*].metadata.name}')

# 循环备份每个命名空间的配置
for namespace in $namespaces; do
  echo -e "\e[1;32mScan Namespace: ${namespace}\e[0m"

  # 创建目录
  mkdir -p "${backupDir}/${namespace}"

  # 备份命名空间
  kubectl --kubeconfig="${configPath}" get namespace "${namespace}" -o yaml > "${backupDir}/${namespace}/${namespace}.yaml"

  types=("cronJob" "daemonSet" "deployment" "job" "statefulSet" "ingress" "service" "configMap" "persistentVolumeClaim" "persistentVolume" "secret")
  for type in "${types[@]}"; do
    # 创建目录
    mkdir -p "${backupDir}/${namespace}/${type}"
    # 读取列表
    resources=$(kubectl --kubeconfig="${configPath}" get "${type}" -n "${namespace}" -o jsonpath='{.items[*].metadata.name}')
    for resource in $resources; do
      echo "[Backup]: ${namespace} / ${type} / ${resource}"
      kubectl --kubeconfig="${configPath}" get "${type}" "${resource}" -n "${namespace}" -o yaml > "$backupDir/${namespace}/${type}/${resource}.yaml"
    done
  done
done


# =================================================================
if [ "${compress^^}" == "Y" ]; then
  # 压缩
  if [ "${backupMode^^}" != "JOB" ]; then
      fileName="k8s_$(date +"%Y%m%d%H%M%S").tar.gz"
  else
    if [ -z "${3}" ]; then
      fileName="k8s_$(date +"%Y%m%d%H%M%S").tar.gz"
    else
      fileName="$3"
    fi
  fi
  tar -zvcf "${fileName}" "${backupDir}"

  # 删除目录
  uuid=$(uuidgen)
  mv -f "${backupDir}" "/tmp/${uuid}"
fi