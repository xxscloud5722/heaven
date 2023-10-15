#!/usr/bin/env bash
set -e

echo -e "\033[4;33mLinux System Name: \033[0m"
cat /etc/redhat-release

echo "--------------------------"

echo -e "\033[4;33mLinux Kernel Name: \033[0m"
uname -a

echo "--------------------------"

echo -e "\033[4;33mDateTime: \033[0m"
date
date "+%Y/%m/%d %H:%M:%S"
echo -e "\033[4;33m-- Zone -- \033[0m"
timedatectl

echo "--------------------------"

echo -e "\033[4;33mCPU: \033[0m"
lscpu

echo "--------------------------"

echo -e "\033[4;33mMemory: \033[0m"
cat /proc/meminfo
echo "----"
free -h



echo "------------------------"

echo -e "\033[4;33mDisk: \033[0m"
fdisk -l


echo "------------------------"

echo -e "\033[4;33mNetwork: \033[0m"
ip addr show

echo -e "\033[4;33m-- Route Show -- \033[0m"
ip route show

echo "------------------------"

echo -e "\033[4;33mFirewall: \033[0m"
systemctl status firewalld