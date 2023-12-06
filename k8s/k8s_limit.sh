#!/usr/bin/env bash
set -e

echo -e "\e[32m================================================================\e[0m"
echo -e "\e[32mVersion: 1.0.0\e[0m"
echo -e "\e[32mAuthor: LX\e[0m"
echo -e "\e[32mArgs\e[0m"
echo -e "\e[32m  - 1 (Optional): Path Config\e[0m"
echo -e "\e[32m  - 2 (Optional): Namespace Name\e[0m"
echo -e "\e[32m  - 3 (Optional): Resource Limit\e[0m"
echo -e "\e[33;1m Only supports Deployments service !\e[0m"
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

function limit() {
  # shellcheck disable=SC2001
  IFS=',-' read -ra values <<< "$resourceConfig"
  values[0]=$(echo "scale=0; ${values[0]} * 1000" | bc)
  values[1]=$(echo "scale=0; ${values[1]} * 1000" | bc)
  echo -e "\e[32;1m=========================================\e[0m"
  echo -e "\e[32;1mReady to update program:\e[0m"
  echo -e "\e[33;1mCPU: ${values[0]}-${values[1]}\e[0m"
  echo -e "\e[33;1mMember: ${values[2]}Mi-${values[3]}Mi\e[0m"
  echo ''
  echo ''
  resources=$(./kubectl --kubeconfig="${configPath}" get deployment -n "${1}" -o jsonpath='{.items[*].metadata.name}')
  for resource in $resources; do
    service=$(./kubectl --kubeconfig="${configPath}" get deployment "${resource}" -n "${namespace}" -o json)
    cpu0=$(echo "$service" | jq -r '.spec.template.spec.containers[0].resources.requests.cpu')
    cpu1=$(echo "$service" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu')
    memory0=$(echo "$service" | jq -r '.spec.template.spec.containers[0].resources.requests.memory')
    memory1=$(echo "$service" | jq -r '.spec.template.spec.containers[0].resources.limits.memory')
    echo ''
    echo ''
    echo -e "\e[33;1m确认对服务 ($resource 当前CPU：$cpu0-$cpu1，内存 $memory0-$memory1) 执行更新吗  (Y/n)?\e[0m" ;
    # shellcheck disable=SC2162
    read status
    if [ "${status^^}" == "Y" ]; then
      echo "[Limit] Deployment: ${1} / ${resource}"
      ./kubectl --kubeconfig="${configPath}" set resources -n "$1" deployment "${resource}" --requests=cpu="${values[0]}m,memory=${values[2]}Mi" --limits=cpu="${values[1]}m,memory=${values[3]}Mi"
    fi
  done
}


# 获取所有命名空间
namespaces=$(./kubectl --kubeconfig="${configPath}" get namespaces -o jsonpath='{.items[*].metadata.name}')

# 打印命名空间
echo -e "\e[32;1mScan Namespace ....\e[0m"
for namespace in $namespaces; do
  echo -e "\e[32m > $namespace\e[0m"
done

if [ -z "${2}" ]; then
  echo "请输入命名空间名称";
  # shellcheck disable=SC2162
  read limitNamespace
else
  limitNamespace="${2}"
fi
if [ -z "${3}" ]; then
  echo "请输入资源限制";
  # shellcheck disable=SC2162
  read resourceConfig
else
  resourceConfig="${3}"
fi
limit "${limitNamespace}"