#!/usr/bin/env bash

# 获取查询结果
echo "Scan Domain ..."
DOMAIN_RESULT=$(./domain scan ./configs/domain.txt --json true)

function send() {
  robot="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=404028b9-1e57-4f95-b6be-c0c2398919d8"
  # shellcheck disable=SC2036
  # shellcheck disable=SC2030
  content="$1" | tr '\n' ' '
  # shellcheck disable=SC2031
  content=${content//"\""/"\\\""}
  request='{"msgtype": "markdown", "markdown": { "content": "#{content}" }}'
  request=${request//"#{content}"/"${content}"}
  curl -X POST -H "Content-Type: application/json" -d "${request}" "${robot}"
}



# Whois 域名
content='### 小丁域名助手  11.27
<font color="#dddddd">--------------------------------------</font>
##### ① Whois检查结果'
domain=$(echo "${DOMAIN_RESULT}" | jq -r '.Domain')
domainLength=$(echo "${domain}" | jq 'length')
for ((i=0; i<domainLength; i++)); do
  item=$(echo "$domain" | jq -r ".[""${i}""]")
  name=$(echo "$item" | jq -r ".Name")
  days=$(echo "$item" | jq -r ".AvailableDays")
  message=$(echo "$item" | jq -r ".Message")
  if [ -z "$message" ]; then
    if [ "$days" -le 30 ]; then
      content="${content}
 > ➢ ${name} ➜ <font color=\"warning\">**${days}天〔即将过期〕**</font>"
    else
      content="${content}
 > ➢ ${name} ➜ <font color=\"#008000\">**${days}天**〔状态正常〕</font>"
    fi
  else
    content="${content}
 > ➢ ${name} ➜ <font color=\"#FF4500\">**${message}〔已有风险〕**</font>"
  fi
done
send "$content"



# SSL 证书
ssl=$(echo "${DOMAIN_RESULT}" | jq -r '.SSL')
sslLength=$(echo "${ssl}" | jq 'length')
sslLengthR=$(expr "$sslLength" / 25 + 1)
for ((j=0; j<sslLengthR; j++)); do
  content="### 小丁域名助手  11.27
 <font color=\"#dddddd\">--------------------------------------</font>
 ##### ② 证书检查结果-$(expr "$j" + 1)"
  for ((i=0; i<25; i++)); do
    index=$(expr "$j" \* 25 + "$i")
    if [ "${index}" -lt "${sslLength}" ]; then
      item=$(echo "$ssl" | jq -r ".[""${index}""]")
      name=$(echo "$item" | jq -r ".Name")
      days=$(echo "$item" | jq -r ".AvailableDays")
      message=$(echo "$item" | jq -r ".Message")
      if [ -z "$message" ]; then
        if [ "$days" -le 30 ]; then
          content="${content}
 > ➢ ${name} ➜ <font color=\"warning\">**${days}天〔即将过期〕**</font>"
        else
          content="${content}
 > ➢ ${name} ➜ <font color=\"#008000\">**${days}天**〔状态正常〕</font>"
        fi
      else
        content="${content}
 > ➢ ${name} ➜ <font color=\"#FF4500\">**${message}〔已有风险〕**</font>"
      fi
    fi
  done
  send "$content"
done


# 总览
sslError=$(echo "${DOMAIN_RESULT}" | jq -r ".SSLError")
sslWarn=$(echo "${DOMAIN_RESULT}" | jq -r ".SSLWarn")
sslSuccess=$(echo "${DOMAIN_RESULT}" | jq -r ".SSLSuccess")
domainError=$(echo "${DOMAIN_RESULT}" | jq -r ".DomainError")
domainWarn=$(echo "${DOMAIN_RESULT}" | jq -r ".DomainWarn")
domainSuccess=$(echo "${DOMAIN_RESULT}" | jq -r ".DomainSuccess")
content=" ### 小丁域名助手  11.27
<font color=\"#dddddd\">--------------------------------------</font>
> ** 域名检查概述： **
> <font color=\"#FF4500\">■ 已有风险：**${domainError}个**</font>
> <font color=\"warning\">★ 即将过期：**${domainWarn}个**</font>
> <font color=\"#008000\">● 检查正常：**${domainSuccess}个**</font>

> ** 证书检查概述： **
> <font color=\"#FF4500\">■ 已有风险：**${sslError}个**</font>
> <font color=\"warning\">★ 即将过期：**${sslWarn}个**</font>
> <font color=\"#008000\">● 检查正常：**${sslSuccess}个**</font>

> **建议：**
> ● 确保域名续期及时，以防止服务中断。
> ● 定期检查域名配置，确保网络和安全设置的有效性。"
send "$content"