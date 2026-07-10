#!/usr/bin/env bash
set -e

echo "[4/5] 配置 Git 和 SSH..."

# --- Git 全局配置 ---
git config --global user.name "Dovahkiin9900"
git config --global user.email "1436386665@qq.com"
git config --global init.defaultBranch main
git config --global core.editor nvim

# --- SSH key ---
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "  → 生成 SSH key"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "1436386665@qq.com" -f "$HOME/.ssh/id_ed25519" -N ""
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              请将以下公钥添加到 GitHub                   ║"
echo "║         https://github.com/settings/ssh/new             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
cat "$HOME/.ssh/id_ed25519.pub"
echo ""
read -rp "添加完成后按 Enter 继续..."

echo "[4/5] Git 和 SSH 配置完成"
