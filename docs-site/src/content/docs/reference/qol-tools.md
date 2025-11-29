---
title: QoL Tools
description: Quality of life tools installed on the server
---

Productivity tools installed to improve daily operations.

## Terminal Tools

### lazydocker
Interactive Docker management TUI.

```bash
lazydocker

# Shortcuts:
# ↑/↓ Navigate
# Enter - View logs/details
# r - Restart
# s - Stop
# d - Remove
# q - Quit
```

### lazygit
Interactive Git management TUI.

```bash
lazygit
```

### btop
Modern resource monitor.

```bash
btop
```

### bat
Better `cat` with syntax highlighting.

```bash
bat file.yml
```

### fzf
Fuzzy finder for files and history.

```bash
# Search files
fzf

# Search command history
Ctrl+R
```

## Shell Aliases

Add to `~/.zshrc`:

```bash
alias ll='ls -lah'
alias dc='docker compose'
alias dps='docker ps'
alias dlogs='docker compose logs -f'
alias update='sudo apt update && sudo apt upgrade -y'
alias gs='git status'
alias gl='git log --oneline -10'
```

## Installation

Most tools installed via apt:

```bash
sudo apt install bat fzf ripgrep tree ncdu htop
```

### lazydocker

```bash
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

### lazygit

```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz
```

## Recommended Workflow

1. Use `lazydocker` for container management
2. Use `lazygit` for Git operations
3. Use `btop` for monitoring
4. Use `bat` instead of `cat`
5. Use `fzf` for file searching
