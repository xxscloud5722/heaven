#!/usr/bin/env bash
set -e

echo -e "\e[32m================================================================\e[0m"
echo -e "\e[32mVersion: 1.0.0\e[0m"
echo -e "\e[32mAuthor: LX\e[0m"
echo -e "\e[32mArgs\e[0m"
echo -e "\e[32m  - 1 (Optional): Path Config\e[0m"
echo -e "\e[32m  - 2 (Optional): Import Directory\e[0m"
echo -e "\e[32m  - 3 (Optional): Namespace Name\e[0m"
echo -e "\e[33;1m Import program ignores 'PV' and 'PVC' !\e[0m"
echo -e "\e[33;1m Import program ignores 'PV' and 'PVC' !!\e[0m"
echo -e "\e[33;1m Import program ignores 'PV' and 'PVC' !!!\e[0m"
echo -e "\e[32m================================================================\e[0m"


# 忽略的命名空间
NAMESPACE_IGNORE=('default' 'kube-node-lease' 'kube-public' 'kube-system' 'persistentVolume')

# 忽略
NAME_IGNORE=('qcloudregistrykey.yaml' 'kube-root-ca.crt.yaml')


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

#
if [ -z "${2}" ]; then
  echo "输入扫描的配置目录 (./k8s_backup)";
  # shellcheck disable=SC2162
  read scanPath
else
  scanPath="${2}"
fi
if [ -z "${scanPath}" ]; then
  scanPath="./k8s_backup"
  echo -e "\e[34mScanPath: scanPath\e[0m"
else
  echo -e "\e[34mScanPath: scanPath\e[0m"
fi




# 读取的命名空间
# shellcheck disable=SC2010
DIRECTORY_LIST=$(ls -l "${scanPath}" | grep '^d' | awk '{print $9}')

# 输出目录列表
echo 'Scan Directory ....'
for item in ${DIRECTORY_LIST}; do
  matched=false
  for match in "${NAMESPACE_IGNORE[@]}"; do
      if [[ "$item" == "$match" ]]; then
        matched=true
        break
      fi
  done
  if [ "$matched" == false ]; then
    NAMESPACE+=("$item")
  fi
done

# 如果没有需要处理的命名空间
if [ ${#NAMESPACE[@]} -eq 0 ]; then
  echo ''
  echo -e "\e[33mNo namespaces need to be imported.\e[0m"
  exit 1
fi

echo -e "\e[32;1mThe following namespaces are ready: \e[0m"
for matching_item in "${NAMESPACE[@]}"; do
  echo -e "\e[32m > $matching_item\e[0m"
done

function run() {
  # 修改yaml
  ./yq "$1" > /tmp/temp_a.yaml
  ./yq 'del(.metadata.uid)' /tmp/temp_a.yaml > /tmp/temp_b.yaml
  ./yq 'del(.metadata.resourceVersion)' /tmp/temp_b.yaml > /tmp/temp_a.yaml
  ./yq 'del(.spec.clusterIP)' /tmp/temp_a.yaml > /tmp/temp_b.yaml
  ./yq 'del(.spec.clusterIPs)' /tmp/temp_b.yaml > /tmp/temp_a.yaml
  # 准备文件
  mv /tmp/temp_a.yaml /tmp/temp.yaml
  ./kubectl apply -f /tmp/temp.yaml --kubeconfig="${configPath}"
}

function import() {
  echo -e "\e[1;32mprocess namespace: ${1}\e[0m"
  types=("cronJob" "daemonSet" "deployment" "job" "statefulSet" "ingress" "service" "configMap" "secret")
  for type in "${types[@]}"; do
    # shellcheck disable=SC2010
    config_files=$(ls -l "${scanPath}/${1}/${type}/" | grep '^-' | awk '{print $9}')
    if [ -z "$config_files" ]; then
      continue
    fi
    echo -e "\e[1;32m[Import] ${1}/${type}\e[0m"
    IFS=$'\n'
    for file in $config_files; do
      matched=false
      for match in "${NAME_IGNORE[@]}"; do
          if [[ "$file" == "$match" ]]; then
            matched=true
            break
          fi
      done
      if [ "$matched" == false ]; then
        echo -e "[Import] ${1}/${type}/${file}"
        run "${scanPath}/${1}/${type}/${file}"
      fi
    done
  done
}


if [ -z "${3}" ]; then
  echo "请输入命名空间名称";
  # shellcheck disable=SC2162
  read importNamespace
else
  importNamespace="${3}"
fi
import "${importNamespace}"