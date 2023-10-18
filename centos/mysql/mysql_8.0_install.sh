#!/usr/bin/env bash
set -e

# 安装wget
echo -e "\033[1;33m wget \033[0m"
sudo yum install wget -y

# yum 安装 简单便捷
sudo rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

# 安装
sudo yum install mysql-server -y