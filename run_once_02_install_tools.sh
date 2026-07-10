#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case $ARCH in
  x86_64) ARCH_ALT="amd64" ;;
  aarch64) ARCH_ALT="arm64" ;;
  *) echo "不支持的架构: $ARCH"; exit 1 ;;
esac

# GitHub 下载，自动回退镜像
gh_download() {
  local url="$1"
  local output="$2"
  echo "  下载: $url"
  if curl -fsSL --connect-timeout 15 "$url" -o "$output" 2>/dev/null; then
    return 0
  fi
  echo "  直连失败，尝试镜像..."
  curl -fsSL --connect-timeout 15 "https://mirror.ghproxy.com/$url" -o "$output"
}

echo "[2/5] 安装 apt 基础工具..."
sudo apt install -y \
  zsh tmux git curl wget unzip fzf stow build-essential

echo "[2/5] 安装二进制工具..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- neovim ---
echo "  → neovim"
gh_download "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" "$TMPDIR/nvim.tar.gz"
sudo tar -C /opt -xzf "$TMPDIR/nvim.tar.gz"
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# --- lazygit ---
echo "  → lazygit"
LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
gh_download "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" "$TMPDIR/lazygit.tar.gz"
tar -C "$TMPDIR" -xzf "$TMPDIR/lazygit.tar.gz" lazygit
sudo mv "$TMPDIR/lazygit" /usr/local/bin/lazygit

# --- ripgrep ---
echo "  → ripgrep"
RG_VERSION=$(curl -fsSL "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep '"tag_name"' | sed 's/.*"\([^"]*\)".*/\1/')
gh_download "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" "$TMPDIR/rg.tar.gz"
tar -C "$TMPDIR" -xzf "$TMPDIR/rg.tar.gz"
sudo mv "$TMPDIR/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" /usr/local/bin/rg

# --- fd ---
echo "  → fd"
FD_VERSION=$(curl -fsSL "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
gh_download "https://github.com/sharkdp/fd/releases/latest/download/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" "$TMPDIR/fd.tar.gz"
tar -C "$TMPDIR" -xzf "$TMPDIR/fd.tar.gz"
sudo mv "$TMPDIR/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" /usr/local/bin/fd

# --- bat ---
echo "  → bat"
BAT_VERSION=$(curl -fsSL "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
gh_download "https://github.com/sharkdp/bat/releases/latest/download/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" "$TMPDIR/bat.tar.gz"
tar -C "$TMPDIR" -xzf "$TMPDIR/bat.tar.gz"
sudo mv "$TMPDIR/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat" /usr/local/bin/bat

# --- eza ---
echo "  → eza"
EZA_VERSION=$(curl -fsSL "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
gh_download "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" "$TMPDIR/eza.tar.gz"
tar -C "$TMPDIR" -xzf "$TMPDIR/eza.tar.gz"
sudo mv "$TMPDIR/eza" /usr/local/bin/eza

# --- zoxide ---
echo "  → zoxide"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# --- tealdeer (tldr) ---
echo "  → tealdeer"
TLDR_VERSION=$(curl -fsSL "https://api.github.com/repos/dbrgn/tealdeer/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
gh_download "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-linux-x86_64-musl" "$TMPDIR/tldr"
sudo mv "$TMPDIR/tldr" /usr/local/bin/tldr
sudo chmod +x /usr/local/bin/tldr

# --- starship ---
echo "  → starship"
curl -sSfL https://starship.rs/install.sh | sh -s -- -y

echo "[2/5] 工具安装完成"
