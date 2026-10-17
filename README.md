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

## 软件

| 软件 | 简介 | 官方链接 |
|---|---|---|
| [Neovim](https://neovim.io/) | 可扩展的终端编辑器 | [neovim.io](https://neovim.io/) |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git 终端界面 | [GitHub](https://github.com/jesseduffield/lazygit) |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | 快速全文搜索工具 | [GitHub](https://github.com/BurntSushi/ripgrep) |
| [fd](https://github.com/sharkdp/fd) | 更易用的文件查找工具 | [GitHub](https://github.com/sharkdp/fd) |
| [pnpm](https://pnpm.io/) | Node.js 包管理器 | [pnpm.io](https://pnpm.io/) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 更智能的目录跳转工具 | [GitHub](https://github.com/ajeetdsouza/zoxide) |
| [starship](https://starship.rs/) | 跨 Shell 的命令提示符 | [starship.rs](https://starship.rs/) |
| [tmux](https://github.com/tmux/tmux) | 终端复用器 | [GitHub](https://github.com/tmux/tmux) |
| [xclip](https://github.com/astrand/xclip) | X11 剪贴板命令行工具 | [GitHub](https://github.com/astrand/xclip) |
| [wl-clipboard](https://github.com/bugaevc/wl-clipboard) | Wayland 剪贴板命令行工具 | [GitHub](https://github.com/bugaevc/wl-clipboard) |
| [Node.js](https://nodejs.org/) | JavaScript 运行环境，pnpm 需要它 | [nodejs.org](https://nodejs.org/) |
| [npm](https://www.npmjs.com/) | Node.js 默认包管理器 | [npmjs.com](https://www.npmjs.com/) |
| [百度输入法](https://srf.baidu.com/) | 中文输入法，需手动安装 | [官网](https://srf.baidu.com/) |

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

配置片段位于 [`configs/tmux.conf`](configs/tmux.conf)。

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
- 鼠标拖选后松开，或在复制模式中按 `y`：使用 Wayland 的 `wl-copy` 或 X11 的 `xclip` 写入系统剪贴板。

把片段放在配置文件末尾，避免后续绑定覆盖它。在本机 Ubuntu 桌面中，拖选后可到其他应用按 `Ctrl+V` 验证。

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
