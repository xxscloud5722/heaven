#!/usr/bin/env bash
set -e

#
yum install -y python38

# pip
wget  https://bootstrap.pypa.io/get-pip.py
python get-pip.py