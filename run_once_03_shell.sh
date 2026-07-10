#!/usr/bin/env bash
set -e

echo "[3/5] 配置 shell 环境..."

# --- oh-my-zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "  → oh-my-zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# --- zsh-autosuggestions ---
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "  → zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# --- zsh-syntax-highlighting ---
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "  → zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --- oh-my-tmux ---
if [ ! -d "$HOME/.tmux" ]; then
  echo "  → oh-my-tmux"
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  cp "$HOME/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
fi

# --- nvm + Node LTS ---
if [ ! -d "$HOME/.nvm" ]; then
  echo "  → nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! node --version &>/dev/null; then
  echo "  → Node LTS"
  nvm install --lts
  nvm use --lts
fi

# --- uv ---
if ! command -v uv &>/dev/null; then
  echo "  → uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# --- thefuck ---
if ! command -v thefuck &>/dev/null; then
  echo "  → thefuck"
  "$HOME/.local/bin/uv" tool install thefuck
fi

# --- lazyvim ---
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "  → lazyvim"
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

echo "[3/5] shell 环境配置完成"
