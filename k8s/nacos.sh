#!/usr/bin/env bash
set -e

echo -e "\e[32m================================================================\e[0m"
echo -e "\e[32mVersion: 1.0.0\e[0m"
echo -e "\e[32mAuthor: LX\e[0m"
echo -e "\e[32mArgs\e[0m"
echo -e "\e[32m  - 1 (Optional): Path Config\e[0m"
echo -e "\e[32m  - 2 (Optional): Mode: ('DEFAULT' or 'JOB')\e[0m"
echo -e "\e[32m================================================================\e[0m"

# 读取配置文件地址
if [ -z "${1}" ]; then
  echo "输入配置文件地址 (nacos_config.json)";
  # shellcheck disable=SC2162
  read configPath
else
  configPath="${1}"
fi
if [ -z "${configPath}" ]; then
  configPath="./nacos_config.json"
  echo -e "\e[34mPath: $configPath\e[0m"
else
  echo -e "\e[34mPath: $configPath\e[0m"
fi


# 模式
backupMode="DEFAULT"
if [ "${2^^}" == "JOB" ]; then
  backupMode="JOB"
fi

# 压缩
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

# 备份路径
backupDir="./nacos"
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

# 读取配置
nacosConfig=$(cat "${configPath}")

# =================================================================
# 社区版本
function community() {
  username=$(echo "${nacosConfig}" | jq -r ".username")
  password=$(echo "${nacosConfig}" | jq -r ".password")
  url=$(echo "${nacosConfig}" | jq -r ".url")

  echo "[Nacos] URI: ${url}"

  # 获取Token
  accessToken=$(curl "${url}"'/nacos/v1/auth/users/login' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-raw 'username='"${username}"'&password='"${password}" \
    --compressed --insecure | jq -r '.accessToken')

  # 明细
  function items() {
    items=$(curl "${url}"'/nacos/v1/cs/configs?dataId=&group=&appName=&config_tags=&pageNo=1&pageSize=200&tenant='"${1}"'&search=accurate&accessToken='"${accessToken}"'&username=nacos' \
                   --compressed --insecure  | jq -r '.pageItems')
    itemsLength=$(echo "${items}" | jq 'length')
    echo -e "\e[1;32m[Nacos] ${1} (${itemsLength})\e[0m"
    mkdir -p "${backupDir}/${1}"
    for ((j=0; j<itemsLength; j++)); do
      dataId=$(echo "${items}" | jq -r ".[""${j}""].dataId")
      content=$(echo "${items}" | jq -r ".[""${j}""].content")
      fileType=$(echo "${items}" | jq -r ".[""${j}""].type")
      if [ "${dataId}" != "null" ] && [ -n "${dataId}" ]; then
        echo "[Nacos] ${1} / ${dataId}"
        echo -e "${content}" > "${backupDir}/${1}/${dataId}.${fileType}"
      fi
    done
  }


  # 获取命名空间
  namespaces=$(curl "${url}"'/nacos/v1/console/namespaces?accessToken='"${accessToken}"'&namespaceId=' | jq -r '.data')
  length=$(echo "$namespaces" | jq 'length')
  for ((i=0; i<length; i++)); do
    namespace=$(echo "$namespaces" | jq -r ".[""${i}""].namespace")
    if [ "${namespace}" != "null" ] && [ -n "${namespace}" ]; then
      echo -e "\e[1;32mScan Namespace: ${namespace}\e[0m"
      items "${namespace}"
    fi
  done
}

# =================================================================
# 企业版本 (阿里云平台)
function enterprise() {
  accessKey=$(echo "${nacosConfig}" | jq -r ".accessKeyId")
  accessSecret=$(echo "${nacosConfig}" | jq -r ".accessKeySecret")
  instanceId=$(echo "${nacosConfig}" | jq -r ".instanceId")

  # 登录
  ./aliyun configure set --profile default --region cn-shanghai --access-key-id "${accessKey}" --access-key-secret "${accessSecret}"


  # 明细
  function items() {
    items=$(./aliyun mse ListNacosConfigs --InstanceId "${instanceId}" --PageNum 1 --PageSize 200 --NamespaceId "$1" | jq -r '.Configurations')
    itemsLength=$(echo "${items}" | jq 'length')
    echo -e "\e[1;32m[Nacos] ${1} (${itemsLength})\e[0m"
    mkdir -p "${backupDir}/${1}"
    for ((j=0; j<itemsLength; j++)); do
      dataId=$(echo "${items}" | jq -r ".[""${j}""].DataId")
      detail=$(./aliyun mse GetNacosConfig --InstanceId "${instanceId}" --DataId "${dataId}" --Group DEFAULT_GROUP --NamespaceId "$1" | jq -r '.Configuration')
      content=$(echo "${detail}" | jq -r ".Content")
      fileType=$(echo "${detail}" | jq -r ".Type")
      if [ "${dataId}" != "null" ] && [ -n "${dataId}" ]; then
       echo "[Nacos] ${1} / ${dataId}"
       echo -e "${content}" > "${backupDir}/${1}/${dataId}.${fileType}"
      fi
    done
  }

  # 获取命名空间
  namespaces=$(echo "${nacosConfig}" | jq -r '.namespaces')
  length=$(echo "$namespaces" | jq 'length')
  for ((i=0; i<length; i++)); do
    namespace=$(echo "$namespaces" | jq -r ".[""${i}""]")
    if [ "${namespace}" != "null" ] && [ -n "${namespace}" ]; then
      echo -e "\e[1;32mScan Namespace: ${namespace}\e[0m"
      items "${namespace}"
    fi
  done
}


nacosType=$(echo "${nacosConfig}" | jq -r ".type")

if [ "${nacosType^^}" == "ALI" ]; then
  enterprise
else
  community
fi

# =================================================================
if [ "${compress^^}" == "Y" ]; then
  # 压缩
  if [ "${backupMode^^}" != "JOB" ]; then
      fileName="nacos_$(date +"%Y%m%d%H%M%S").tar.gz"
  else
    if [ -z "${3}" ]; then
      fileName="nacos_$(date +"%Y%m%d%H%M%S").tar.gz"
    else
      fileName="$3"
    fi
  fi
  tar -zvcf "${fileName}" "${backupDir}"

  # 删除目录
  uuid=$(uuidgen)
  mv -f "${backupDir}" "/tmp/${uuid}"
fi