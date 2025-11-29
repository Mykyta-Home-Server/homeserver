---
title: ZSH Setup
description: Configure ZSH with Oh My Zsh and productivity plugins
---

Guide for setting up ZSH with Oh My Zsh and essential plugins.

## Installation

```bash
# Install ZSH
sudo apt install zsh -y

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set as default shell
chsh -s $(which zsh)
```

## Essential Plugins

### Syntax Highlighting

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Autosuggestions

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### Enable Plugins

Edit `~/.zshrc`:

```bash
plugins=(
  git
  docker
  docker-compose
  zsh-syntax-highlighting
  zsh-autosuggestions
)
```

## Useful Aliases

Add to `~/.zshrc`:

```bash
alias ll='ls -lah'
alias dc='docker compose'
alias dps='docker ps'
alias dlogs='docker compose logs -f'
alias update='sudo apt update && sudo apt upgrade -y'
```

## VS Code Integration

Add to `.vscode/settings.json`:

```json
{
  "terminal.integrated.defaultProfile.linux": "zsh"
}
```
