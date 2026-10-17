# Ubuntu 开发环境安装

这个仓库只提供一次性的 Ubuntu 环境安装脚本，不接管用户的 Shell、tmux 或 Neovim 配置。

## 使用方式

在 Ubuntu 上执行：

```bash
chmod +x setup.sh
./setup.sh
```

脚本会：

1. 根据 Ubuntu 版本和版本代号配置中科大软件源。
2. 直接写入对应格式的中科大源并执行 `apt-get update`。
3. 安装 Neovim、lazygit、ripgrep、fd、pnpm、zoxide、starship、tmux 和剪贴板工具。
4. 询问是否生成 SSH key。

SSH key 可以直接通过参数选择：

```bash
./setup.sh --ssh       # 生成 ~/.ssh/id_ed25519；已有则跳过
./setup.sh --no-ssh    # 跳过 SSH key
```

非交互执行时默认跳过 SSH key，需要生成时使用 `--ssh`。

脚本不会修改：

- `~/.zshrc`
- `~/.bashrc`
- `~/.tmux.conf`
- `~/.tmux.conf.local`
- `~/.config/nvim/`
- 已有 SSH 私钥

## 百度输入法

手动安装步骤见 [`install.md`](install.md)。

## 手动加入 tmux 配置

配置片段位于 [`manual/tmux.conf`](manual/tmux.conf)。

把它的内容加入以下任意一个文件：

```text
~/.tmux.conf
```

或者使用 Oh My Tmux 时加入：

```text
~/.tmux.conf.local
```

它包含：

- `set -g mouse on`：启用鼠标。
- `set -g set-clipboard on`：启用 tmux 与终端的剪贴板同步。
- 复制模式中按 `y`：使用 Wayland 的 `wl-copy` 或 X11 的 `xclip` 写入系统剪贴板。

加入后重新加载：

```bash
tmux source-file ~/.tmux.conf
```

如果使用 `~/.tmux.conf.local`，仍然执行上面的命令即可。

## 手动加入 Neovim 配置

配置片段位于 [`manual/nvim-options.lua`](manual/nvim-options.lua)。

把其中两行加入：

```text
~/.config/nvim/lua/config/options.lua
```

如果使用 LazyVim，目标文件通常就是这个文件；文件不存在时创建它。

加入内容：

```lua
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
```

作用是：

- `vim.opt.mouse = "a"`：在 Neovim 中启用鼠标。
- `vim.opt.clipboard = "unnamedplus"`：让 Neovim 使用系统剪贴板。

## SSH key

使用 `--ssh` 后，脚本只在下面的私钥不存在时生成：

```text
~/.ssh/id_ed25519
```

已有私钥不会被覆盖。生成后把下面文件的内容添加到 GitHub 或其他 Git 服务：

```text
~/.ssh/id_ed25519.pub
```

## APT 源

Ubuntu 24.04 及更新版本使用 deb822 格式的 `ubuntu.sources`；旧版本使用传统的 `sources.list` 格式。

脚本不会备份 APT 源。它会清理旧版本脚本留下的 `*.disabled-by-dotfiles` 文件，避免 APT 报无效扩展名警告。
