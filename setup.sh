#!/usr/bin/env bash
set -Eeuo pipefail

SSH_MODE="ask"
BAIDU_INPUT_URL="${BAIDU_INPUT_URL:-https://srf.baidu.com/download/baidupinyin_1.0.0.0_amd64.deb}"

usage() {
  cat <<'EOF'
用法：
  ./setup.sh                 安装环境，最后询问是否生成 SSH key
  ./setup.sh --ssh           安装环境并生成 SSH key（已有则跳过）
  ./setup.sh --no-ssh        安装环境，不生成 SSH key
  BAIDU_INPUT_URL=... ./setup.sh

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

backup_apt_file() {
  local file="$1"
  local backup_dir="$2"
  if [[ -f "$file" ]]; then
    run_as_root cp -a -- "$file" "$backup_dir/$(basename "$file")"
  fi
}

configure_ustc_sources() {
  local version_id="${VERSION_ID:-}"
  local codename="$VERSION_CODENAME"
  local backup_dir="/etc/apt/ustc-backup-$(date +%Y%m%d-%H%M%S)"

  log "配置中科大 Ubuntu 软件源（${version_id} ${codename}）"
  run_as_root mkdir -p -- "$backup_dir"
  backup_apt_file /etc/apt/sources.list "$backup_dir"
  backup_apt_file /etc/apt/sources.list.d/ubuntu.sources "$backup_dir"

  if [[ "$version_id" == 24.* || "$version_id" == 25.* ]]; then
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
    if [[ -f /etc/apt/sources.list ]]; then
      run_as_root mv -- /etc/apt/sources.list "/etc/apt/sources.list.disabled-by-dotfiles"
    fi
  else
    run_as_root tee /etc/apt/sources.list >/dev/null <<EOF
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename} main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
    if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
      run_as_root mv -- /etc/apt/sources.list.d/ubuntu.sources \
        /etc/apt/sources.list.d/ubuntu.sources.disabled-by-dotfiles
    fi
  fi

  printf 'APT 源备份：%s\n' "$backup_dir"
}

install_apt_packages() {
  log '更新 APT 并安装基础依赖'
  run_as_root apt-get update
  run_as_root apt-get install -y \
    ca-certificates curl git wget unzip xz-utils build-essential openssh-client \
    tmux neovim ripgrep fd-find nodejs npm \
    xclip wl-clipboard \
    fcitx fcitx-config-gtk fcitx-frontend-gtk3 fcitx-frontend-qt5 \
    im-config libfcitx-qt5-0

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

install_baidu_input() {
  if dpkg-query -W -f='${Status}' baidupinyin 2>/dev/null | grep -q 'install ok installed'; then
    printf '百度输入法已安装，跳过\n'
    return
  fi
  [[ "$(dpkg --print-architecture)" == amd64 ]] || {
    printf '跳过百度输入法：官方 Linux deb 当前仅适用于 amd64\n'
    return
  }

  log '安装百度输入法 Linux 版'
  local tmp="$HOME/.cache/dotfiles"
  mkdir -p "$tmp"
  curl -fL "$BAIDU_INPUT_URL" -o "$tmp/baidupinyin.deb"
  run_as_root apt-get install -y "$tmp/baidupinyin.deb"
  rm -f -- "$tmp/baidupinyin.deb"
  im-config -n fcitx || true
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
  install_baidu_input
  maybe_generate_ssh

  cat <<'EOF'

安装完成。
请重新打开终端，使软件安装器写入的环境变量生效。
tmux 和 Neovim 的手动配置见 README.md。
EOF
}

main "$@"
