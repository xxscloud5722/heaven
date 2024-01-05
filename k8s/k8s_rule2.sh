#!/usr/bin/env bash
set -e


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
namespace=${2}
if [ "${3^^}" == "DEV" ]; then
  apiMemory="512Mi"
  otherMemory="128Mi"
  checkJarOps=1
elif [ "${3^^}" == "TEST" ]; then
  apiMemory="512Mi"
  otherMemory="128Mi"
  checkJarOps=1
elif [ "${3^^}" == "PREV" ]; then
  apiMemory="512Mi"
  otherMemory="128Mi"
  checkJarOps=0
elif [ "${3^^}" == "PROD" ]; then
  apiMemory="1024Mi"
  otherMemory="128Mi"
  checkJarOps=0
else
  echo "environment value error"
  exit 1
fi



function checkEnv() {
  local array1=("${@}")
  if [ "$checkJarOps" -eq 1 ]; then
    checkNames=("JAR_OPS" "JAVA_OPS" "APPLICATION_ENV" "APPLICATION_SYSTEM" "AGENT")
  else
    checkNames=("JAR_OPS" "APPLICATION_ENV" "APPLICATION_SYSTEM" "AGENT")
  fi
  for element in "${checkNames[@]}"; do
      # shellcheck disable=SC2199
      # shellcheck disable=SC2076
      if [[ ! " ${array1[@]} " =~ " ${element} " ]]; then
          return 1
      fi
  done
  return 0
}

function checkSecretsEnv() {
  local array1=("${@}")
  checkNames=("billbear" "aliyun-shanghai" "billbear-shanghai")
  for element in "${checkNames[@]}"; do
      # shellcheck disable=SC2199
      # shellcheck disable=SC2076
      if [[ ! " ${array1[@]} " =~ " ${element} " ]]; then
          return 1
      fi
  done
  return 0
}

# 检查无状态 + 有状态
types=("deployment" "statefulSet")
for type in "${types[@]}"; do
  resources=$(./kubectl --kubeconfig="${configPath}" get "${type}" -n "${namespace}" -o jsonpath='{.items[*].metadata.name}')
  for resource in $resources; do
    # 读取详情
    value=$(./kubectl --kubeconfig="${configPath}" get "${type}" "${resource}" -n "${namespace}" -o json)

    # 检查是否有名称标签
    result=$(echo "${value}" | jq -r '.metadata.labels.app')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} metadata.labels.app: 没有设置应用名称\e[0m"
    fi
    if [ "$result" != "$resource" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} metadata.labels.app: 每次与Kubernetes服务名称不一致\e[0m"
    fi

    # 检查是否有服务类型
    module=$(echo "${value}" | jq -r '.metadata.labels.module')
    if [ "$module" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} metadata.labels.module 没有服务类型\e[0m"
    fi

    # 检查是否有中文名称
    result=$(echo "${value}" | jq -r '.metadata.annotations.chineseName')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} metadata.annotations.chinese-name: 没有中文名称\e[0m"
    fi

    # 检查是否有中文描述
    result=$(echo "${value}" | jq -r '.metadata.annotations.chineseDescription')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} metadata.annotations.chinese-description: 没有中文描述\e[0m"
    fi

    # 检查资源限制是否是正确
    if [ "$module" = "api" ]; then
      # 后端
      requestMemory=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.requests.memory')
      if [ "$requestMemory" != "$apiMemory" ]; then
          echo -e "\e[31m${namespace} / ${type} / ${resource} 最低内存资源: 配置不正确或者没有值应该为 ($apiMemory)\e[0m"
      fi
      limitMemory=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.limits.memory')
      if [ "$limitMemory" = "$apiMemory" ]; then
          echo -e "\e[31m${namespace} / ${type} / ${resource} 最大内存资源: 配置不正确或者没有值应该为 ($apiMemory)\e[0m"
      fi
    else
      # 前端 + 其他服务 Nginx
      requestMemory=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.requests.memory')
      if [ "$requestMemory" != "$otherMemory" ]; then
          echo -e "\e[31m${namespace} / ${type} / ${resource} 最低内存资源: 配置不正确或者没有值应该为 ($otherMemory)\e[0m"
      fi
      limitMemory=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.limits.memory')
      if [ "$limitMemory" = "$otherMemory" ]; then
          echo -e "\e[31m${namespace} / ${type} / ${resource} 最大内存资源: 配置不正确或者没有值应该为 ($otherMemory)\e[0m"
      fi
    fi

    requestCPU=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.requests.cpu')
    if [ "$requestCPU" != "100m" ]; then
        echo -e "\e[31m${namespace} / ${type} / ${resource} 最低CPU资源: 配置不正确或者没有值应该为 (0.01)\e[0m"
    fi
    limitCPU=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu')
    if [ "$limitCPU" != "4" ]; then
        echo -e "\e[31m${namespace} / ${type} / ${resource} 最大CPU资源: 配置不正确或者没有值应该为 (4)\e[0m"
    fi

    # 如果是后端服务检查环境变量
    if [ "$module" = "api" ]; then
      envs=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].env')
      if [ "$envs" != "null" ]; then
        if checkEnv "$(echo "$envs" | jq -r '.[].name')"; then
          echo ""
        else
          echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量应该为:JAR_OPS,  JAVA_OPS, APPLICATION_ENV, APPLICATION_SYSTEM, AGENT; 当前缺少环境变量 \e[0m"
        fi
        array_length=$(echo "${envs}" | jq 'length')
        for ((i=0; i<array_length; i++)); do
          itemName=$(echo "$envs" | jq -r ".[$i].name")
          itemValue=$(echo "$envs" | jq -r ".[$i].value")
          itemValueRefName=$(echo "$envs" | jq -r ".[$i].valueFrom.secretKeyRef.name")
          itemValueRefOPS=$(echo "$envs" | jq -r ".[$i].valueFrom.secretKeyRef.JAVA_OPS")
          if [ "$checkJarOps" -eq 1 ] && [ "$itemName" = "JAR_OPS" ] && [ "$itemValue" = "--spring.cloud.nacos.discovery.weight=9999" ]; then
            echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量(JAR_OPS)错误, 值必须是: --spring.cloud.nacos.discovery.weight=9999\e[0m"
          fi
          if [ "$itemValueRefName" = "JAVA_OPS" ] && [ "$itemValueRefName" = "billbear" ] && [ "$itemValueRefOPS" = "JAVA_OPS" ]; then
            echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量(JAVA_OPS)错误, 值必须是应用保密字典: billbear - JAVA_OPS\e[0m"
          fi
          if [ "$itemValueRefName" = "APPLICATION_ENV" ] && [ "$itemValueRefName" = "billbear" ] && [ "$itemValueRefOPS" = "APPLICATION_ENV" ]; then
            echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量(APPLICATION_ENV)错误, 值必须是应用保密字典: billbear - APPLICATION_ENV\e[0m"
          fi
          if [ "$itemValueRefName" = "APPLICATION_SYSTEM" ] && [ "$itemValueRefName" = "billbear" ] && [ "$itemValueRefOPS" = "APPLICATION_SYSTEM" ]; then
            echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量(APPLICATION_SYSTEM)错误, 值必须是应用保密字典: billbear - APPLICATION_SYSTEM\e[0m"
          fi
          if [ "$itemValueRefName" = "AGENT" ] && [ "$itemValueRefName" = "billbear" ] && [ "$itemValueRefOPS" = "AGENT" ]; then
            echo -e "\e[31m${namespace} / ${type} / ${resource} 环境变量(AGENT)错误, 值必须是应用保密字典: billbear - AGENT\e[0m"
          fi
        done
      fi
    fi

    # 检查探针 目前忽略, 如果有探针必须大于 75s
    result=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].livenessProbe')
    if [ "$result" != "null" ]; then
      result=$(echo "${result}" | jq -r '.initialDelaySeconds')
      if [ "$result" -lt 75 ]; then
        echo -e "\e[31m${namespace} / ${type} /${resource} 存活探针(initialDelaySeconds)必须大于: 75s\e[0m"
      fi
    fi
    result=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].startupProbe')
    if [ "$result" != "null" ]; then
      result=$(echo "${result}" | jq -r '.initialDelaySeconds')
      if [ "$result" -lt 75 ]; then
        echo -e "\e[31m${namespace} / ${type} /${resource} 启动探针(initialDelaySeconds)必须大于: 75s\e[0m"
      fi
    fi
    result=$(echo "${value}" | jq -r '.spec.template.spec.containers[0].readinessProbe')
    if [ "$result" != "null" ]; then
      result=$(echo "${result}" | jq -r '.initialDelaySeconds')
      if [ "$result" -lt 75 ]; then
        echo -e "\e[31m${namespace} / ${type} /${resource} 就绪探针(initialDelaySeconds)必须大于: 75s\e[0m"
      fi
    fi
  done
done


# 检查密钥
secrets=$(./kubectl --kubeconfig="${configPath}" get secret -n "${namespace}" -o jsonpath='{.items[*].metadata.name}')
if checkSecretsEnv "$(echo "$envs" | jq -r '.[].name')"; then
  echo ""
else
  echo -e "\e[31m${namespace} / ${type} 保密字典应该有:billbear, aliyun-shanghai, billbear-shanghai; 当前缺少必要的保密字典 \e[0m"
fi
for resource in ${secrets}; do
  value=$(./kubectl --kubeconfig="${configPath}" get secret "${resource}" -n "${namespace}" -o json)
  result=$(echo "${value}" | jq -r '.type')
  if [ "$resource" = "aliyun-shanghai" ] && [ "$result" != "kubernetes.io/dockerconfigjson" ]; then
    echo -e "\e[31m${namespace} / ${type} / ${resource} 不是Docker授权类型\e[0m"
  fi
  if [ "$resource" = "billbear-shanghai" ] && [ "$result" != "kubernetes.io/dockerconfigjson" ]; then
    echo -e "\e[31m${namespace} / ${type} / ${resource} 不是Docker授权类型\e[0m"
  fi
  if [ "$resource" = "billbear" ]; then
    result=$(echo "${value}" | jq -r '.data.AGENT')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} 没有字段: AGENT \e[0m"
    fi
    result=$(echo "${value}" | jq -r '.data.APPLICATION_ENV')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} 没有字段: APPLICATION_ENV \e[0m"
    fi
    result=$(echo "${value}" | jq -r '.data.APPLICATION_SYSTEM')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} 没有字段: APPLICATION_SYSTEM \e[0m"
    fi
    result=$(echo "${value}" | jq -r '.data.JAVA_OPS')
    if [ "$result" = "null" ]; then
      echo -e "\e[31m${namespace} / ${type} / ${resource} 没有字段: JAVA_OPS \e[0m"
      echo -e "\e[31m${namespace} / ${type} / ${resource} JAVA_OPS 值应该为: --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED -Duser.timezone=GMT+08 -Dlogging.config=/app/log4j2.xml -Dlogging.level.root=INFO -Dbillbear.nacos.config.namespace=Nacos 命名空间 -Dbillbear.nacos.config.server-addr=Nacos服务器地址 -Dserver.port=8080 \e[0m"
    fi
  fi
done


# 检查svc
services=$(./kubectl --kubeconfig="${configPath}" get service -n "${namespace}" -o jsonpath='{.items[*].metadata.name}')
for resource in ${services}; do
  # 检查Service 名称 必须 svc 结果
  if [[ "$resource" != *-svc ]]; then
    echo -e "\e[31m${1} / Service / ${resource} 名称必须以svc 结尾\e[0m"
  fi

  value=$(./kubectl --kubeconfig="${configPath}" get service "${resource}" -n "${namespace}" -o json)

  # 检查绑定的变量 必须是app 绑定
  result=$(echo "${value}" | jq -r '.spec.selector.app')
  if [ "$result" = "null" ]; then
    echo -e "\e[31m${1} / Service / ${resource} spec.selector.app: 必须使用app标签绑定\e[0m"
  fi
done


# 检查pvc
pvcs=$(./kubectl --kubeconfig="${configPath}" get persistentVolumeClaim -n "${namespace}" -o jsonpath='{.items[*].metadata.name}')
for resource in ${pvcs}; do
  # 检查PersistentVolumeClaim 名称 必须 pvc 结果
  if [[ "$resource" != *-pvc ]]; then
    echo -e "\e[31m${1} / PersistentVolumeClaim / ${resource} 名称必须以pvc 结尾\e[0m"
  fi
done