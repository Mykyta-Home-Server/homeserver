#!/bin/bash
# Quality of Life Tools Installation Script
# For Ubuntu Server 22.04 LTS
# Last Updated: 2024-11-21

set -e  # Exit on error

echo "=========================================="
echo "🚀 Installing Quality of Life Tools"
echo "=========================================="
echo ""

# Update package list
echo "📦 Updating package list..."
sudo apt update

# Category 1: Essential Command Line Tools
echo ""
echo "⭐ Installing Essential Command Line Tools..."
sudo apt install -y zsh curl wget git

# Category 2: File & Directory Navigation
echo ""
echo "🗂️  Installing File Navigation Tools..."
sudo apt install -y bat exa fzf tree

# Fix bat naming issue on Ubuntu
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true

# Category 3: System Monitoring
echo ""
echo "📊 Installing System Monitoring Tools..."
sudo apt install -y htop ncdu glances

# Install btop via snap
if command -v snap &> /dev/null; then
    echo "Installing btop..."
    sudo snap install btop 2>/dev/null || echo "btop install skipped"
fi

# Category 4: Network & Debugging
echo ""
echo "🌐 Installing Network Tools..."
sudo apt install -y iproute2 netcat jq net-tools dnsutils

# Install duf via snap
if command -v snap &> /dev/null; then
    echo "Installing duf..."
    sudo snap install duf-utility 2>/dev/null || echo "duf install skipped"
fi

# Category 5: Git Enhancements
echo ""
echo "🔀 Installing Git Tools..."
sudo apt install -y tig

# Category 6: Text Editing
echo ""
echo "✏️  Configuring nano..."
cat > ~/.nanorc << 'EOF'
set linenumbers
set autoindent
set tabsize 4
set mouse
EOF

# Category 7: Miscellaneous
echo ""
echo "🔧 Installing Miscellaneous Tools..."
sudo apt install -y tldr ripgrep tmux

# Update tldr database
echo "Updating tldr database..."
tldr --update || true

# Install Oh My Zsh (skip if already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    echo "🎨 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install zsh plugins
echo ""
echo "🔌 Installing ZSH plugins..."

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Configure ZSH plugins
echo ""
echo "⚙️  Configuring ZSH..."

# Backup existing .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Update plugins in .zshrc
sed -i 's/^plugins=.*/plugins=(git docker docker-compose sudo command-not-found history aliases colored-man-pages z zsh-syntax-highlighting zsh-autosuggestions)/' "$HOME/.zshrc"

# Add fzf key bindings if available
if [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ]; then
    grep -qxF 'source /usr/share/doc/fzf/examples/key-bindings.zsh' "$HOME/.zshrc" || \
        echo 'source /usr/share/doc/fzf/examples/key-bindings.zsh' >> "$HOME/.zshrc"
fi

if [ -f "/usr/share/doc/fzf/examples/completion.zsh" ]; then
    grep -qxF 'source /usr/share/doc/fzf/examples/completion.zsh' "$HOME/.zshrc" || \
        echo 'source /usr/share/doc/fzf/examples/completion.zsh' >> "$HOME/.zshrc"
fi

# Add useful aliases
echo ""
echo "📝 Adding useful aliases..."
cat >> "$HOME/.zshrc" << 'EOF'

# ========== Custom Aliases ==========

# Better ls with exa
alias ls='exa'
alias ll='exa -la'
alias la='exa -a'
alias lt='exa --tree --level=2'

# Better cat with bat
alias cat='bat --paging=never'
alias catt='bat'  # Original bat with paging

# Docker shortcuts
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dim='docker images'
alias dlog='docker logs -f'

# System monitoring
alias mon='btop'
alias disk='duf'
alias ports='ss -tulpn'

# Git shortcuts (in addition to Oh My Zsh git plugin)
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gaa='git add .'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd /opt/homeserver'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System updates
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
EOF

# Install lazygit
echo ""
echo "🦥 Installing lazygit..."
if ! command -v lazygit &> /dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit.tar.gz lazygit
    echo "✅ lazygit installed"
else
    echo "✅ lazygit already installed"
fi

# Install lazydocker (will install after Docker is available)
echo ""
echo "🐳 Checking for lazydocker..."
if command -v docker &> /dev/null; then
    if ! command -v lazydocker &> /dev/null; then
        echo "Installing lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo "✅ lazydocker installed"
    else
        echo "✅ lazydocker already installed"
    fi
else
    echo "⚠️  Docker not installed yet. Run this after Docker installation:"
    echo "   curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
fi

# Install dive
echo ""
echo "🔍 Installing dive..."
if ! command -v dive &> /dev/null; then
    wget -q https://github.com/wagoodman/dive/releases/download/v0.11.0/dive_0.11.0_linux_amd64.deb
    sudo dpkg -i dive_0.11.0_linux_amd64.deb
    rm -f dive_0.11.0_linux_amd64.deb
    echo "✅ dive installed"
else
    echo "✅ dive already installed"
fi

# Fix /opt/homeserver permissions
echo ""
echo "🔧 Fixing /opt/homeserver permissions..."
sudo chown -R $USER:$USER /opt/homeserver

# Change default shell to ZSH
echo ""
echo "🐚 Setting ZSH as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to ZSH..."
    chsh -s $(which zsh)
    echo "✅ Default shell changed to ZSH"
    echo ""
    echo "⚠️  IMPORTANT: You need to LOG OUT and LOG BACK IN for this to take effect!"
    echo "   Until then, you can use: exec zsh"
else
    echo "✅ ZSH is already your default shell"
fi

# Clean up
echo ""
echo "🧹 Cleaning up..."
sudo apt autoremove -y

echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. LOG OUT and LOG BACK IN (required for ZSH to become default)"
echo "   OR temporarily start ZSH with: exec zsh"
echo ""
echo "2. After logging back in, verify ZSH is active:"
echo "   echo \$SHELL    # Should show: /usr/bin/zsh"
echo ""
echo "3. Verify installations:"
echo "   - Type 'bat --version' to test bat"
echo "   - Type 'exa --version' to test exa"
echo "   - Type 'lazygit --version' to test lazygit"
echo "   - Type 'btop' to test system monitor"
echo ""
echo "4. Useful commands to try:"
echo "   - 'll' - better ls"
echo "   - 'Ctrl+R' - fuzzy search command history"
echo "   - 'lazygit' - visual git interface"
echo "   - 'btop' - system monitor"
echo "   - 'lazydocker' - Docker interface (after Docker install)"
echo ""
echo "5. All aliases are in ~/.zshrc"
echo "   Run 'alias' to see all available shortcuts"
echo ""
echo "Happy coding! 🚀"
