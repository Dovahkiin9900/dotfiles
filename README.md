# dotfiles

用 chezmoi 部署个人 Linux 开发环境，并同步 tmux、LazyVim 配置。

## 新机器部署

需要 x86_64 Ubuntu/Debian、curl、sudo 和网络。部署会更换 APT 源、配置 Git/SSH、安装工具，
并备份后覆盖本地 tmux、Neovim 配置。Git 身份写在 `run_once_04_git_ssh.sh`，使用前按需修改。

VMware 用户先安装：`sudo apt install open-vm-tools-desktop`。

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Dovahkiin9900/dotfiles
```

按提示将 SSH 公钥添加到 GitHub。部署完成后切换默认 Shell，再重新登录：

```bash
chsh -s "$(which zsh)"
```

主要工具：
- Shell：zsh、oh-my-zsh、自动建议与语法高亮、starship。
- 终端与编辑器：tmux / oh-my-tmux、Neovim / LazyVim、lazygit。
- 命令行：rg、fd、bat、eza、fzf、zoxide、tldr、thefuck。
- 开发环境：uv、nvm / Node LTS；桌面环境额外安装 JetBrainsMono Nerd Font。

## 同步与应用配置

以下命令在仓库根目录执行，需要 Bash、GNU coreutils 和 rsync（缺少时运行 `sudo apt install rsync`）。

| 本地配置（固定路径） | 仓库副本 |
|---|---|
| `~/.tmux.conf.local` | `configs/tmux.conf.local` |
| `~/.config/nvim/` | `configs/nvim/` |

**按修改位置选择命令：**

| 操作 | 命令 |
|---|---|
| 修改本地后，保存到仓库 | `./scripts/configs.sh sync` |
| 修改仓库副本后，应用到本地 | `./scripts/configs.sh deploy` |

`sync` 同步新增、修改和删除，保留插件锁文件，排除 Git 元数据、日志和缓存。
检查内容后自行提交推送，新机器才能从 GitHub 获取这些修改：

```bash
git add configs
git diff --cached -- configs  # 确认修改正确，且不含密钥等私密信息
git commit -m "Update tmux and LazyVim config"
git push
```

### 覆盖与备份

`deploy` 只更新配置，要求已安装 oh-my-tmux（`~/.tmux/.tmux.conf` 存在）。
它会重建 `~/.tmux.conf` 框架链接，覆盖 `~/.tmux.conf.local`，并**整体替换 Neovim 配置目录，包括删除本地独有文件**。

每次部署的旧配置单独保存在 `~/.local/state/dotfiles/backups/` 下，命令会显示本次备份路径。
备份包含原有的 `tmux.conf`、`tmux.conf.local`、`nvim`。恢复时放回原位置；恢复 nvim 前先移走当前目录，避免合并残留。

使用本仓库执行 `chezmoi apply` / `update` 也会触发覆盖。对当前仓库执行完整部署用
`chezmoi --source "$PWD" apply`；默认 source 目录可能是另一份仓库。
`chezmoi diff` 不展示这两套配置的内容差异。

## 修改位置

- tmux：修改 `configs/tmux.conf.local` 或 `~/.tmux.conf.local`，应用后执行 `tmux source-file ~/.tmux.conf`。
- LazyVim：在 `configs/nvim/` 或本地 nvim 目录中修改以下文件，应用后重启 Neovim。

| LazyVim 文件 | 用途 |
|---|---|
| `lua/config/options.lua` | 行号、缩进等编辑器选项 |
| `lua/config/keymaps.lua` | 快捷键 |
| `lua/config/autocmds.lua` | 自动命令 |
| `lua/plugins/*.lua` | 插件及其设置；`example.lua` 当前不生效，自定义配置另建文件 |
| `lazyvim.json` | extras 等设置，可用 `:LazyExtras` 管理 |
| `lazy-lock.json` | 插件版本锁定，可用 `:Lazy restore` 恢复 |

新机器首次启动 Neovim 需要联网安装插件。

## 项目入口

- `dot_zshrc`：由 chezmoi 管理的 `~/.zshrc`。
- `run_once_*.sh`：工具与环境安装。
- `run_after_06_configs.sh.tmpl`：每次 apply 后调用 `scripts/configs.sh deploy`。
