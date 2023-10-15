#!/usr/bin/env bash

if [ ! -n "$1" ] ;then
echo "Not 'Host'"
exit 1
fi

if [ ! -n "$2" ] ;then
echo "Not 'Port'"
exit 1
fi

# Ping 检查
echo -e "\033[1;33m ping $1 \033[0m"
timeout -s SIGINT 8s ping -n -c 5 $1

# telnet
echo -e "\033[1;33m telnet $1:$2 \033[0m"
timeout -s SIGKILL 3s telnet $1 $2