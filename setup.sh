#!/usr/bin/env bash
set -Eeuo pipefail

SSH_MODE="ask"

usage() {
  cat <<'EOF'
用法：
  ./setup.sh                 安装环境，最后询问是否生成 SSH key
  ./setup.sh --ssh           安装环境并生成 SSH key（已有则跳过）
  ./setup.sh --no-ssh        安装环境，不生成 SSH key

项目不会修改 ~/.zshrc、~/.bashrc、tmux 或 Neovim 配置。
EOF
}

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令：$1"
}

run_as_root() {
  sudo "$@"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --ssh) SSH_MODE="yes" ;;
      --no-ssh) SSH_MODE="no" ;;
      -h|--help) usage; exit 0 ;;
      *) die "未知参数：$1" ;;
    esac
    shift
  done
}

check_system() {
  [[ -f /etc/os-release ]] || die '找不到 /etc/os-release'
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == ubuntu ]] || die "只支持 Ubuntu，当前系统：${PRETTY_NAME:-未知}"
  [[ "${EUID:-$(id -u)}" -ne 0 ]] || die '请使用普通用户运行，脚本会在需要时调用 sudo'
  need_command sudo
  need_command curl
  need_command dpkg
  need_command apt-get
  [[ -n "${VERSION_CODENAME:-}" ]] || die '无法识别 Ubuntu 版本代号'

  case "$(dpkg --print-architecture)" in
    amd64|arm64) ;;
    *) die "暂不支持的架构：$(dpkg --print-architecture)" ;;
  esac

  printf '系统：%s\n' "${PRETTY_NAME:-Ubuntu}"
  printf '代号：%s\n' "$VERSION_CODENAME"
}

configure_ustc_sources() {
  local version_id="${VERSION_ID:-}"
  local codename="$VERSION_CODENAME"

  log "配置中科大 Ubuntu 软件源（${version_id} ${codename}）"
  # 清理旧版本脚本留下的无效文件名；APT 会扫描该目录并发出警告。
  run_as_root rm -f -- \
    /etc/apt/sources.list.disabled-by-dotfiles \
    /etc/apt/sources.list.d/ubuntu.sources.disabled-by-dotfiles

  if [[ "$version_id" == 24.* || "$version_id" == 25.* || "$version_id" == 26.* ]]; then
    run_as_root tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu/
Suites: ${codename} ${codename}-updates ${codename}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu/
Suites: ${codename}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    run_as_root rm -f -- /etc/apt/sources.list
  else
    run_as_root tee /etc/apt/sources.list >/dev/null <<EOF
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename} main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
    run_as_root rm -f -- /etc/apt/sources.list.d/ubuntu.sources
  fi
}

install_apt_packages() {
  log '更新 APT 并安装基础依赖'
  run_as_root apt-get update
  run_as_root apt-get install -y \
    ca-certificates curl git wget unzip xz-utils build-essential openssh-client \
    tmux neovim ripgrep fd-find nodejs npm \
    xclip wl-clipboard

  mkdir -p "$HOME/.local/bin"
  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    run_as_root ln -sfn -- "$(command -v fdfind)" /usr/local/bin/fd
    printf '已创建 fd 命令：/usr/local/bin/fd\n'
  fi
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    printf 'lazygit 已安装，跳过\n'
    return
  fi

  local arch asset version tmp
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) asset="x86_64" ;;
    arm64) asset="arm64" ;;
    *) die "lazygit 不支持的架构：$arch" ;;
  esac
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v([^"]+)".*/\1/p' | head -n1)"
  [[ -n "$version" ]] || die '无法获取 lazygit 版本'
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' RETURN
  curl -fL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${asset}.tar.gz" \
    -o "$tmp/lazygit.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  run_as_root install -m 0755 "$tmp/lazygit" /usr/local/bin/lazygit
}

install_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    printf 'pnpm 已安装，跳过\n'
    return
  fi
  log '安装 pnpm'
  run_as_root npm install --global pnpm
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/zoxide" ]]; then
    printf 'zoxide 已安装，跳过\n'
    return
  fi
  log '安装 zoxide'
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    printf 'starship 已安装，跳过\n'
    return
  fi
  log '安装 starship'
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

generate_ssh_key() {
  if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    printf 'SSH 私钥已存在，跳过生成：%s\n' "$HOME/.ssh/id_ed25519"
    [[ -f "$HOME/.ssh/id_ed25519.pub" ]] || ssh-keygen -y -f "$HOME/.ssh/id_ed25519" > "$HOME/.ssh/id_ed25519.pub"
    printf '公钥：%s\n' "$HOME/.ssh/id_ed25519.pub"
    return
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N '' -C "$(id -un)@$(hostname)"
  chmod 600 "$HOME/.ssh/id_ed25519"
  chmod 644 "$HOME/.ssh/id_ed25519.pub"
  printf 'SSH 公钥：%s\n' "$HOME/.ssh/id_ed25519.pub"
  cat "$HOME/.ssh/id_ed25519.pub"
}

maybe_generate_ssh() {
  case "$SSH_MODE" in
    yes) generate_ssh_key ;;
    no) printf '按参数跳过 SSH key\n' ;;
    ask)
      if [[ -t 0 ]]; then
        read -r -p '是否生成 SSH key？[y/N] ' answer
        case "$answer" in
          y|Y|yes|YES) generate_ssh_key ;;
          *) printf '跳过 SSH key\n' ;;
        esac
      else
        printf '非交互模式，跳过 SSH key；如需生成请使用 ./setup.sh --ssh\n'
      fi
      ;;
  esac
}

main() {
  parse_args "$@"
  check_system
  configure_ustc_sources
  install_apt_packages
  install_lazygit
  install_pnpm
  install_zoxide
  install_starship
  maybe_generate_ssh

  cat <<'EOF'

安装完成。
请重新打开终端，使软件安装器写入的环境变量生效。
tmux 和 Neovim 的手动配置见 README.md。
EOF
}

main "$@"
