# 安装说明

## 一键安装其他软件

```bash
./setup.sh --no-ssh
```

## 手动安装最小依赖

```bash
sudo apt update
sudo apt install -y neovim tmux ripgrep fd-find nodejs npm xclip wl-clipboard
sudo npm install -g pnpm
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

lazygit：详见 [官方安装教程](https://github.com/jesseduffield/lazygit#installation)

pnpm：详见 [官方安装教程](https://pnpm.io/installation)

zoxide：详见 [官方安装教程](https://github.com/ajeetdsouza/zoxide#installation)

starship：详见 [官方安装教程](https://starship.rs/guide/)

## 百度输入法 Linux

下载 ZIP：

<https://srf.baidu.com/?c=j&e=d&from=1000e&platform=ubuntu&ref=index_entrance_android_click>

解压：

```bash
unzip <下载的文件名>.zip
```
