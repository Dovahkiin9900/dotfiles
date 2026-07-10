#!/usr/bin/env bash
set -e

if ! command -v apt &>/dev/null; then
  echo "[skip] 非 apt 系统，跳过换源"
  exit 0
fi

echo "[1/5] 换中科大源..."

# 备份原始sources.list
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 换成中科大镜像
sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list

sudo apt update
echo "[1/5] 换源完成"
