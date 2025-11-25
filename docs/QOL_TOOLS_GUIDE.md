# Quality of Life Tools - Quick Reference Guide

## 📦 What This Script Installs

### Essential Categories:

1. **Shell Improvements** - ZSH + Oh My Zsh with plugins
2. **File Navigation** - bat, exa, fzf, tree
3. **System Monitoring** - htop, btop, ncdu, glances, duf
4. **Network Tools** - ss, netcat, jq, dnsutils
5. **Git Tools** - tig, lazygit
6. **Docker Tools** - lazydocker, dive
7. **Misc Utilities** - tldr, ripgrep, tmux

---

## 🚀 Installation Instructions

### Run the script:
```bash
cd /opt/homeserver
./setup-quality-of-life.sh
```

### ⚠️ IMPORTANT: After installation completes

The script automatically changes your default shell to ZSH, but **you MUST log out and log back in** for this to take effect!

```bash
# After script finishes:
exit

# SSH back in - ZSH will now be your default shell
ssh mykyta@home-server

# Verify ZSH is active:
echo $SHELL    # Should show: /usr/bin/zsh
```

**Common mistake:** Running `exec zsh` is only temporary! You must fully disconnect and reconnect SSH for the change to persist.

---

## 🎯 Most Useful Tools to Know

### 1. **ZSH with Oh My Zsh** ⭐⭐⭐⭐⭐
**What it does:** Better shell with autocomplete, syntax highlighting, git integration

**Try it:**
- Start typing a command and press TAB for suggestions
- Type a few letters of a previous command and press ↑ arrow
- Your prompt will show git branch and status automatically

**Key Features:**
- `Ctrl + R` - Search command history (fuzzy search with fzf)
- Auto-suggestions from history (press → arrow to accept)
- Syntax highlighting (green = valid, red = invalid)

---

### 2. **fzf (Fuzzy Finder)** ⭐⭐⭐⭐⭐
**What it does:** Interactive search for files, directories, command history

**Keyboard Shortcuts:**
```bash
Ctrl + R    # Search command history
Ctrl + T    # Search files in current directory
Alt + C     # Navigate to a directory
```

**This is a GAME CHANGER for productivity!**

---

### 3. **bat (Better cat)** ⭐⭐⭐⭐
**What it does:** View files with syntax highlighting and line numbers

**Usage:**
```bash
bat filename.yml          # View with syntax highlighting
bat -A filename.txt       # Show hidden characters
alias cat='bat'           # Already added in script
```

---

### 4. **exa (Better ls)** ⭐⭐⭐⭐
**What it does:** Colorful file listings

**Aliases (already configured):**
```bash
ll        # Long listing with details
la        # Show hidden files
lt        # Tree view (2 levels)
```

**Manual usage:**
```bash
exa -la                    # Detailed listing
exa --tree --level=3       # Tree view 3 levels deep
exa -l --sort=modified     # Sort by modification time
exa -l --sort=size         # Sort by file size
```

**Note:** The Ubuntu package version of `exa` doesn't include git integration. For git-aware listings, use `lazygit` or regular `git status`.

---

### 5. **btop** ⭐⭐⭐⭐⭐
**What it does:** Beautiful system monitor (CPU, RAM, disk, network, processes)

**Usage:**
```bash
btop          # Launch system monitor
# Or use alias:
mon
```

**Controls:**
- `M` - Toggle menu
- `q` - Quit
- Mouse works! Click on processes to interact

**Why it's better than htop:** Modern UI, more details, better graphs

---

### 6. **lazygit** ⭐⭐⭐⭐⭐
**What it does:** Visual git interface in terminal (no more typing git commands!)

**Usage:**
```bash
cd /opt/homeserver
lazygit
```

**Controls:**
- `↑/↓` - Navigate
- `Space` - Stage/unstage
- `c` - Commit
- `P` - Push
- `p` - Pull
- `?` - Help menu

**This will change how you use git!**

---

### 7. **lazydocker** ⭐⭐⭐⭐⭐
**What it does:** Visual Docker interface (manage containers, view logs, stats)

**Usage:**
```bash
lazydocker
```

**Controls:**
- `↑/↓` - Navigate
- `Enter` - View details/logs
- `r` - Restart container
- `d` - Remove container
- `?` - Help menu

**Essential for managing your home server!**

---

### 8. **ncdu** ⭐⭐⭐⭐
**What it does:** Find what's eating your disk space

**Usage:**
```bash
ncdu /opt/homeserver      # Analyze directory
ncdu /                    # Analyze entire system (slow)
```

**Controls:**
- `↑/↓` - Navigate
- `Enter` - Enter directory
- `d` - Delete (be careful!)
- `q` - Quit

---

### 9. **jq** ⭐⭐⭐⭐
**What it does:** Process and format JSON (essential for Docker, APIs)

**Usage:**
```bash
docker inspect caddy | jq '.[0].State'        # View container state
docker inspect caddy | jq '.[0].NetworkSettings.Networks'  # View networks
curl -s https://api.github.com/users/anthropics | jq '.name'
```

---

### 10. **tldr** ⭐⭐⭐⭐
**What it does:** Simplified man pages with practical examples

**Usage:**
```bash
tldr tar          # Quick tar examples
tldr docker       # Quick docker examples
tldr find         # Quick find examples
```

**Much faster than reading full man pages!**

---

### 11. **ripgrep (rg)** ⭐⭐⭐⭐
**What it does:** FAST search through files (respects .gitignore)

**Usage:**
```bash
rg "error" /opt/homeserver     # Find "error" in all files
rg "TODO"                      # Find TODO comments
rg "function.*export" --type ts  # Search TypeScript files
```

---

### 12. **tmux** ⭐⭐⭐⭐
**What it does:** Keep sessions running even if SSH disconnects

**Basic usage:**
```bash
tmux              # Start new session
tmux ls           # List sessions
tmux attach       # Attach to last session

# Inside tmux:
Ctrl+B then D     # Detach (session keeps running)
Ctrl+B then C     # Create new window
Ctrl+B then %     # Split pane vertically
Ctrl+B then "     # Split pane horizontally
```

---

## 🔥 Useful Aliases (Already Configured)

```bash
# File operations
ll          # exa -la --git (better ls)
la          # exa -a (show hidden)
lt          # exa --tree (tree view)

# Docker shortcuts
d           # docker
dc          # docker compose
dps         # docker ps
dpsa        # docker ps -a
dim         # docker images
dlog        # docker logs -f

# System monitoring
mon         # btop
disk        # duf (disk usage)
ports       # ss -tulpn (list open ports)

# Git shortcuts
gs          # git status
gl          # git log (pretty)
gaa         # git add .

# Navigation
..          # cd ..
...         # cd ../..
home        # cd /opt/homeserver

# System
update      # Full system update + cleanup
```

---

## 📚 Tool Categories by Use Case

### When working with files:
```bash
ll                    # List files with details
bat filename.yml      # View file contents
rg "search term"      # Search in files
ncdu                  # Check disk space
```

### When working with Docker:
```bash
lazydocker           # Visual Docker manager (BEST)
dps                  # List containers
dlog container-name  # Follow logs
dive image-name      # Inspect image layers
```

### When working with Git:
```bash
lazygit              # Visual git manager (BEST)
gs                   # Git status
gl                   # Git log
```

### When monitoring system:
```bash
btop                 # Full system monitor (BEST)
htop                 # Alternative system monitor
disk                 # Disk usage (pretty)
ports                # Check open ports
```

### When learning commands:
```bash
tldr command         # Quick examples
man command          # Full manual
```

---

## 🎓 Learning Path

### Week 1: Get comfortable with basics
1. Use `ll` instead of `ls`
2. Use `bat` to view files
3. Use `Ctrl+R` to search command history
4. Try `btop` to monitor system

### Week 2: Git and Docker
1. Use `lazygit` for all git operations
2. Use `lazydocker` to manage containers
3. Learn `jq` for JSON parsing
4. Use `tmux` for long-running tasks

### Week 3: Advanced
1. Master `fzf` keyboard shortcuts
2. Use `rg` for code searching
3. Customize ZSH theme
4. Create your own aliases

---

## 🔧 Customization

### Add more aliases:
Edit `~/.zshrc` and add your own:
```bash
nano ~/.zshrc
# Scroll to bottom and add:
alias myalias='some-command'
```

Then reload:
```bash
source ~/.zshrc
```

### Change ZSH theme:
```bash
nano ~/.zshrc
# Find: ZSH_THEME="robbyrussell"
# Change to: ZSH_THEME="agnoster"  # or any theme
```

Popular themes: `agnoster`, `powerlevel10k`, `spaceship`

---

## 🆘 Troubleshooting

### ⚠️ ZSH works in regular SSH but not in VS Code? (VERY COMMON - VS Code Issue!)

**Problem:** Your default shell is ZSH (confirmed with `grep $USER /etc/passwd`), regular SSH works fine, but VS Code integrated terminal still shows bash.

**Why:** VS Code Remote SSH has **its own terminal settings** that override your system defaults!

**Quick Fix:**

I've created `.vscode/settings.json` in the project that tells VS Code to use ZSH. To apply it:

1. **Reload VS Code window:**
   - Press `Ctrl+Shift+P`
   - Type: "Reload Window"
   - Press Enter

2. **Open new terminal:**
   - Press `` Ctrl+` `` (backtick) to open terminal
   - Should now be ZSH!

3. **Verify:**
   ```bash
   echo $SHELL    # Should show /usr/bin/zsh
   ps -p $$       # Should show zsh
   ```

**If still not working:**

Set it in your VS Code User Settings (applies to all remote servers):
1. `Ctrl+Shift+P` → "Preferences: Open Settings (JSON)"
2. Add these lines:
   ```json
   "terminal.integrated.defaultProfile.linux": "zsh"
   ```
3. Reload window

**Check the settings file:** [.vscode/settings.json](.vscode/settings.json)

---

### ⚠️ ZSH not starting automatically after login? (COMMON ISSUE)

**Problem:** You installed ZSH and ran `exec zsh` which works, but when you log out and log back in, you're back to bash.

**Why this happens:**
When you install ZSH, changing the default shell requires you to:
1. Run `chsh -s $(which zsh)` (the script does this automatically)
2. **LOG OUT completely and LOG BACK IN** (SSH disconnect/reconnect)

The `exec zsh` command only starts ZSH for the current session - it's temporary!

**Solution:**
```bash
# 1. Verify chsh was run (script does this automatically):
grep $USER /etc/passwd
# Should show: /usr/bin/zsh at the end

# 2. MUST exit SSH completely and reconnect:
exit
# Then SSH back in:
ssh mykyta@home-server

# 3. Verify it worked:
echo $SHELL
# Should show: /usr/bin/zsh (NOT /bin/bash)

# If it shows /bin/bash, you didn't log out completely
```

**Check which shell you're ACTUALLY using:**
```bash
echo $SHELL           # Shows default shell
ps -p $$              # Shows ACTUAL current shell
which $SHELL          # Shows path to current shell
```

**Still not working?**

Check if ZSH is in allowed shells:
```bash
cat /etc/shells       # ZSH should be listed

# Verify:
grep zsh /etc/shells
# Should show: /usr/bin/zsh

# If missing, add it:
command -v zsh | sudo tee -a /etc/shells
```

Then try changing shell again:
```bash
chsh -s $(which zsh)
exit
# SSH back in
```

---

### Aliases not working?
```bash
source ~/.zshrc
# Or restart ZSH:
exec zsh
```

---

### bat command not found?
```bash
# Ubuntu uses 'batcat', create alias:
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

# Add to PATH in ~/.zshrc:
export PATH="$HOME/.local/bin:$PATH"
source ~/.zshrc
```

---

### lazydocker command not found?
```bash
# Install after Docker is installed:
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

---

### fzf keyboard shortcuts not working?
```bash
# Add to ~/.zshrc:
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

# Then reload:
source ~/.zshrc
```

---

## 📖 Official Documentation

- **Oh My Zsh:** https://ohmyz.sh/
- **fzf:** https://github.com/junegunn/fzf
- **bat:** https://github.com/sharkdp/bat
- **exa:** https://the.exa.website/
- **btop:** https://github.com/aristocratos/btop
- **lazygit:** https://github.com/jesseduffield/lazygit
- **lazydocker:** https://github.com/jesseduffield/lazydocker
- **tmux:** https://github.com/tmux/tmux/wiki

---

## 💡 Pro Tips

1. **Press TAB often** - ZSH autocomplete is amazing
2. **Use Ctrl+R** - Fuzzy search is faster than scrolling history
3. **Learn lazygit first** - It'll save you hours
4. **Keep tmux running** - Never lose work from SSH disconnects
5. **Create aliases** - For commands you use 10+ times a day
6. **Use tldr** - Before reading full man pages
7. **Explore with fzf** - Ctrl+T to find files interactively
8. **Always log out completely** - Shell changes require full logout (not just `exec zsh`)

---

## ✅ Verification Checklist

After installation AND logging back in, verify everything works:

```bash
# Shell verification (MOST IMPORTANT)
echo $SHELL              # Should show: /usr/bin/zsh (NOT /bin/bash)
ps -p $$                 # Should show: zsh

# File tools
bat --version
exa --version
fzf --version

# System monitoring
btop --version
ncdu --version

# Git/Docker tools
lazygit --version
dive --version

# Network tools
jq --version
rg --version

# Aliases
alias | grep ll          # Should show exa alias
ll                       # Should work and show colored output

# fzf integration
# Press: Ctrl+R            # Should open fuzzy finder
```

---

## 🚨 IMPORTANT REMINDERS

### 1. **You MUST log out and log back in after installation**
   - `exec zsh` is only temporary!
   - Exit SSH completely: `exit`
   - Reconnect: `ssh mykyta@home-server`

### 2. **Verify ZSH is active after reconnecting**
   ```bash
   echo $SHELL    # Should be /usr/bin/zsh
   ```

### 3. **If still not working, check /etc/passwd**
   ```bash
   grep $USER /etc/passwd
   # Should end with: /usr/bin/zsh
   ```

---

**Remember:** These tools have a learning curve, but they'll make you 10x more productive once you get comfortable!

Start with the basics (ll, bat, Ctrl+R) and gradually adopt more tools as you go.

**Happy hacking!** 🚀
