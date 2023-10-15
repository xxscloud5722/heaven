#!/usr/bin/env bash

function confirm() {
read -r -p "Are You Sure? [Y/n] " input
case $input in
    [yY][eE][sS]|[yY])
		echo "Yes"
		$1
		;;

    [nN][oO]|[nN])
		echo "No"
		$2
    ;;
    *)
		echo "Invalid input..."
		exit 1
		;;
esac
}

function install_docker() {
echo "Installing docker ..."

# 卸载
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# 安装基础组件
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

# 设置官方源
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker 以及常用插件
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker
systemctl start docker
systemctl enable docker
}

echo "Confirm install Docker?"
confirm install_docker