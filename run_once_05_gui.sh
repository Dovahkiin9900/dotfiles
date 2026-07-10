#!/usr/bin/env bash
set -e

# 只在有桌面环境的机器上执行
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
  echo "[skip] 无桌面环境，跳过 GUI 安装"
  exit 0
fi

echo "[5/5] 安装 GUI 工具..."

# --- Kitty 终端 ---
if ! command -v kitty &>/dev/null; then
  echo "  → kitty"
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
  # 添加桌面图标
  cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" "$HOME/.local/share/applications/" 2>/dev/null || true
fi

# --- JetBrainsMono Nerd Font ---
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if ! fc-list | grep -qi "JetBrainsMono"; then
  echo "  → JetBrainsMono Nerd Font"
  FONT_VERSION=$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
  MIRROR_URL="https://mirror.ghproxy.com/$FONT_URL"

  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT

  if ! curl -fsSL --connect-timeout 15 "$FONT_URL" -o "$TMPDIR/font.tar.xz" 2>/dev/null; then
    echo "  直连失败，尝试镜像..."
    curl -fsSL --connect-timeout 15 "$MIRROR_URL" -o "$TMPDIR/font.tar.xz"
  fi

  tar -C "$FONT_DIR" -xJf "$TMPDIR/font.tar.xz" '*.ttf' 2>/dev/null || \
  tar -C "$FONT_DIR" -xJf "$TMPDIR/font.tar.xz"

  fc-cache -fv "$FONT_DIR" > /dev/null
  echo "  字体安装完成"
fi

echo "[5/5] GUI 工具安装完成"
