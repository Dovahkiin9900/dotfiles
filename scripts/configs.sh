#!/usr/bin/env bash
# sync: copy local tmux/LazyVim settings into this checkout.
# deploy: back up local settings, then replace them with this checkout's copies.
# Requires Bash, rsync and GNU coreutils; never installs tools or contacts a network.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
CONFIGS_DIR="$REPO_DIR/configs"
# Local configuration and backups use fixed paths under HOME.
NVIM_DIR="$HOME/.config/nvim"
BACKUP_ROOT="$HOME/.local/state/dotfiles/backups"

# Print a usage or validation error to stderr and exit without further changes.
die() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

# Validate both source configs before creating a snapshot or overwriting anything.
# $1 is the tmux customization file; $2 is the LazyVim configuration directory.
require_configs() {
  [[ -f "$1" && -r "$1" ]] || die "缺少可读的 tmux 配置：$1"
  [[ -d "$2" && -f "$2/init.lua" && -r "$2/init.lua" ]] || \
    die "缺少 LazyVim 配置目录或 init.lua：$2"
}

# Build a complete snapshot in $3 from tmux file $1 and nvim directory $2.
# Dereference symlinks so the repository contains portable copies, not local paths.
# Any copy failure aborts before either destination configuration is replaced.
copy_configs() {
  cp -L -- "$1" "$3/tmux.conf.local"
  mkdir -- "$3/nvim"
  rsync -aL \
    --exclude='.git' --exclude='.DS_Store' \
    --exclude='/.cache/' --exclude='/cache/' --exclude='/data/' \
    --exclude='/state/' --exclude='/lazy/' --exclude='/node_modules/' \
    --exclude='/undo/' --exclude='/swap/' --exclude='/backup/' \
    --exclude='*.log' --exclude='*.swp' --exclude='*.swo' --exclude='*~' \
    -- "$2/" "$3/nvim/"
}

# Keep links as links in the backup; deploying never writes through an old link.
# $1 may be absent or a broken symlink; $2 is its path in the new backup directory.
backup_if_present() {
  if [[ -e "$1" || -L "$1" ]]; then
    cp -a -- "$1" "$2"
  fi
}

[[ $# -eq 1 ]] || die '用法：scripts/configs.sh sync|deploy'
case "$1" in
  sync|deploy) ;;
  -h|--help)
    printf '用法：scripts/configs.sh sync|deploy\n  sync    本地配置 → 仓库副本\n  deploy  备份本地配置，再用仓库副本覆盖\n'
    exit 0
    ;;
  *) die "未知命令：$1（支持 sync、deploy）" ;;
esac
command -v rsync >/dev/null 2>&1 || die '需要 rsync；Ubuntu/Debian：sudo apt install rsync'
[[ "$HOME" == /* ]] || die 'HOME 必须使用绝对路径'
[[ ! -L "$CONFIGS_DIR" && ! -L "$CONFIGS_DIR/nvim" && ! -L "$CONFIGS_DIR/tmux.conf.local" ]] || \
  die '仓库 configs 及其配置副本必须是普通文件/目录，不能是符号链接'
[[ ! -e "$CONFIGS_DIR/tmux.conf.local" || -f "$CONFIGS_DIR/tmux.conf.local" ]] || \
  die "仓库 tmux 副本必须是普通文件：$CONFIGS_DIR/tmux.conf.local"

if [[ "$1" == sync ]]; then
  require_configs "$HOME/.tmux.conf.local" "$NVIM_DIR"
else
  require_configs "$CONFIGS_DIR/tmux.conf.local" "$CONFIGS_DIR/nvim"
  [[ -f "$HOME/.tmux/.tmux.conf" ]] || \
    die '尚未安装 oh-my-tmux（~/.tmux/.tmux.conf）；请先完成 README 中的新机器部署'
  for file in "$HOME/.tmux.conf" "$HOME/.tmux.conf.local"; do
    [[ ! -d "$file" || -L "$file" ]] || die "目标是目录，拒绝覆盖：$file"
  done
fi

stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT

if [[ "$1" == sync ]]; then
  copy_configs "$HOME/.tmux.conf.local" "$NVIM_DIR" "$stage"
  mkdir -p -- "$CONFIGS_DIR"
  # Replace the whole snapshot so removed files AND directories stay removed.
  rm -rf -- "$CONFIGS_DIR/nvim"
  mv -- "$stage/nvim" "$CONFIGS_DIR/nvim"
  mv -f -- "$stage/tmux.conf.local" "$CONFIGS_DIR/tmux.conf.local"
  printf '已同步本地配置到 %s；请检查 git diff 后自行提交。\n' "$CONFIGS_DIR"
else
  copy_configs "$CONFIGS_DIR/tmux.conf.local" "$CONFIGS_DIR/nvim" "$stage"
  mkdir -p -- "$BACKUP_ROOT"
  backup=$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S).XXXXXX")
  backup_if_present "$HOME/.tmux.conf" "$backup/tmux.conf"
  backup_if_present "$HOME/.tmux.conf.local" "$backup/tmux.conf.local"
  backup_if_present "$NVIM_DIR" "$backup/nvim"
  printf '本地配置备份：%s\n' "$backup"

  # Remove destinations themselves, not their symlink targets. A fresh tree also
  # prevents a deleted plugin file from being loaded again on another machine.
  mkdir -p -- "$(dirname -- "$NVIM_DIR")"
  rm -f -- "$HOME/.tmux.conf" "$HOME/.tmux.conf.local"
  rm -rf -- "$NVIM_DIR"
  mv -- "$stage/nvim" "$NVIM_DIR"
  mv -- "$stage/tmux.conf.local" "$HOME/.tmux.conf.local"
  ln -s -- "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  printf '已用仓库副本覆盖 tmux 和 LazyVim 配置。\n'
fi
