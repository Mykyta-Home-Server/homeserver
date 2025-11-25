# Quick Reference Guide

**Purpose:** Fast lookup for common commands and info during development

---

## Current System Info

```bash
VM Name:    Ubuntu-HomeServer-PoC
Hostname:   home-server
Username:   mykyta
Current IP: 192.168.1.200
SSH:        ssh mykyta@home-server
            or: ssh mykyta@192.168.1.200
Project:    /opt/homeserver
```

---

## Network Commands

```bash
# Check IP
hostname -I
ip addr show eth0 | grep inet

# Check MAC address (for router reservation)
ip link show eth0 | grep ether

# Renew DHCP
sudo dhclient -r eth0 && sudo dhclient eth0

# Test connectivity
ping -c 4 google.com
ping -c 4 192.168.1.1

# Check routing
ip route | grep default
```

---

## System Commands

```bash
# Update system
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

# System info
lsb_release -a    # OS version
nproc             # CPU cores
free -h           # RAM
df -h             # Disk space
uname -a          # Kernel info

# Shutdown/Reboot
sudo shutdown -h now    # Shutdown
sudo reboot            # Reboot
```

---

## Docker Commands (After Installation)

```bash
# Check versions
docker --version
docker compose version

# Container management
docker ps                    # Running containers
docker ps -a                 # All containers
docker logs <container>      # View logs
docker exec -it <container> bash  # Enter container

# Docker Compose
cd /opt/homeserver
docker compose up -d         # Start services
docker compose down          # Stop services
docker compose ps            # Status
docker compose logs -f       # Follow logs
docker compose restart <service>  # Restart one service

# Cleanup
docker system prune -a       # Remove unused data (careful!)
docker image prune           # Remove unused images
docker volume prune          # Remove unused volumes
```

---

## Git Commands

```bash
cd /opt/homeserver

# Status & Changes
git status
git log --oneline -10
git diff

# Commit changes
git add .
git commit -m "Your message"
git push

# Undo (careful!)
git checkout -- <file>       # Discard changes to file
git reset HEAD~1             # Undo last commit (keep changes)
```

---

## File Editing

```bash
# Edit file
nano <filename>
# Save: Ctrl+O, Enter
# Exit: Ctrl+X

# View file
cat <filename>
less <filename>  # Scrollable (q to quit)
head -20 <filename>  # First 20 lines
tail -20 <filename>  # Last 20 lines
tail -f <filename>   # Follow (live updates)
```

---

## Directory Navigation

```bash
cd /opt/homeserver          # Go to project
cd ~                        # Go to home
cd ..                       # Go up one level
pwd                         # Print current directory
ls -la                      # List all files (detailed)
mkdir -p path/to/dir        # Create directory
tree -L 2                   # Show directory tree (2 levels)
```

---

## Permissions

```bash
# Change owner
sudo chown -R $USER:$USER /path/to/dir

# Change permissions
chmod +x script.sh          # Make executable
chmod 644 file.txt          # Read/write for owner, read for others
chmod 755 directory/        # Full for owner, read/execute for others

# Check permissions
ls -la <file>
```

---

## SSH (From Windows)

```powershell
# Connect
ssh mykyta@home-server
# or: ssh mykyta@192.168.1.200

# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy key to server
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh mykyta@home-server "cat >> ~/.ssh/authorized_keys"

# Remove old host key (if IP changed)
ssh-keygen -R 192.168.1.200
ssh-keygen -R home-server
```

---

## Common File Locations

```bash
# System
/etc/netplan/              # Network configuration
/etc/docker/               # Docker configuration
/var/log/                  # System logs

# Project
/opt/homeserver/           # Main project directory
/opt/homeserver/docker-compose.yml
/opt/homeserver/.env
/opt/homeserver/volumes/   # Container data

# User
~/.ssh/                    # SSH keys and config
~/.bashrc                  # Shell configuration
~/.gitconfig               # Git configuration
```

---

## Troubleshooting

### Can't SSH
```bash
# On VM - check SSH is running
sudo systemctl status ssh

# Restart SSH
sudo systemctl restart ssh

# Check firewall (if enabled)
sudo ufw status
sudo ufw allow ssh
```

### Docker Issues
```bash
# Check Docker is running
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check if user is in docker group
groups $USER

# Add user to docker group
sudo usermod -aG docker $USER
# Then log out and back in!
```

### Network Issues
```bash
# Check gateway
ip route | grep default

# DNS test
nslookup google.com

# Restart networking
sudo systemctl restart systemd-networkd
```

### Disk Full
```bash
# Check disk usage
df -h
du -sh /opt/homeserver/volumes/*

# Clean Docker
docker system df
docker system prune -a

# Clean apt cache
sudo apt clean
```

---

## Useful Aliases (Add to ~/.bashrc)

```bash
# Edit ~/.bashrc
nano ~/.bashrc

# Add these at the end:
alias ll='ls -lah'
alias gs='git status'
alias dc='docker compose'
alias dps='docker ps'
alias dlogs='docker compose logs -f'
alias update='sudo apt update && sudo apt upgrade -y'

# Apply changes
source ~/.bashrc
```

---

## Port Reference (For Later)

| Service | Internal Port | External Access |
|---------|---------------|-----------------|
| Caddy | 80, 443 | Reverse proxy |
| Plex | 32400 | Media server |
| qBittorrent | 8080 | Torrent client |
| Portainer | 9000 | Docker management |
| MCP Server | 3000 | Automation API |

---

## Emergency Commands

```bash
# If system is unresponsive
# From Hyper-V console, login and:
sudo reboot now

# If Docker containers eating all resources
docker stop $(docker ps -q)

# If disk is full
docker system prune -a --volumes
sudo apt clean
```

---

## Hyper-V Shortcuts (On Windows)

```
From Hyper-V Manager:
- Start VM: Right-click → Start
- Connect: Right-click → Connect
- Checkpoint (Snapshot): Right-click → Checkpoint
- Settings: Right-click → Settings

Ctrl+Alt+Left Arrow: Release mouse from VM
```

---

## VS Code Remote SSH (After Setup)

```
F1 → "Remote-SSH: Connect to Host" → mykyt@192.168.1.100
F1 → "Remote-SSH: Open Configuration File" (to save connection)

Once connected:
- File → Open Folder → /opt/homeserver
- Terminal: Ctrl+` (opens terminal on remote machine)
```

---

## Getting Help

```bash
# Command manual
man <command>
<command> --help

# Search for package
apt search <keyword>

# Check if command exists
which <command>
command -v <command>
```

---

**Remember:** This is a PoC/learning environment. Experiment freely! You can always restore from Hyper-V checkpoint if something breaks.