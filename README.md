# dotfiles

## 新机器一键部署

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Dovahkiin9900/dotfiles
```

这一行会自动：
1. 安装 chezmoi
2. clone 本仓库
3. 换中科大源
4. 安装所有 CLI 工具
5. 配置 zsh + tmux + nvim
6. 配置 Git 并生成 SSH key
7. GUI 机器额外安装 JetBrainsMono Nerd Font

完成后手动切换默认 shell：

```bash
chsh -s $(which zsh)
```

重新登录后生效。

## 已安装工具

| 工具 | 说明 |
|---|---|
| zsh + oh-my-zsh | Shell |
| zsh-autosuggestions | 历史命令自动建议 |
| zsh-syntax-highlighting | 命令语法高亮 |
| tmux + oh-my-tmux | 终端复用 |
| neovim + lazyvim | 编辑器 |
| lazygit | Git TUI |
| ripgrep (rg) | 超快搜索 |
| fd | 更好的 find |
| bat | 带高亮的 cat |
| eza | 带图标的 ls |
| fzf | 模糊搜索 |
| zoxide | 智能跳目录 |
| starship | 漂亮的提示符 |
| tealdeer (tldr) | 命令速查 |
| uv | Python 包管理 |
| thefuck | 命令自动纠错 |
| nvm + Node LTS | Node 版本管理 |
| JetBrainsMono NF | Nerd Font（GUI） |
