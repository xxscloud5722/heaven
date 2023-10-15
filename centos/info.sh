#!/usr/bin/env bash
set -e

echo "Linux System Name: "
cat /etc/redhat-release

echo "--------------------------"

echo "Linux Kernel Name: "
uname -a

echo "--------------------------"

echo "CPU: "
lscpu

echo "--------------------------"

echo "Memory: "
cat /proc/meminfo
echo "----"
free -h



echo "------------------------"

echo "Disk: "
fdisk -l


