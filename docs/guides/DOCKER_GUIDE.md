# Docker Complete Guide - Ubuntu Server 22.04

**Last Updated:** 2025-11-24

---

## 📋 Table of Contents

1. [Part 1: Installation & Setup](#part-1-installation--setup)
2. [Part 2: Quick Commands Reference](#part-2-quick-commands-reference)
3. [Part 3: Recovery Procedures](#part-3-recovery-procedures)
4. [Part 4: Troubleshooting](#part-4-troubleshooting)

---

# Part 1: Installation & Setup

## 📋 Overview

This guide walks you through installing Docker and Docker Compose on your home server. You'll learn WHY each step is necessary and WHAT each command does.

## 🎯 What We're Installing

1. **Docker Engine** - The core Docker runtime that manages containers
2. **Docker Compose V2** - Tool for defining and running multi-container applications
3. **lazydocker** - Beautiful terminal UI for managing Docker (optional but highly recommended)

## 📚 Why Docker for Your Home Server?

### Benefits:
- **Isolation** - Each service runs in its own container (Plex, qBittorrent, etc.)
- **Easy Updates** - Pull new images and restart containers
- **Portability** - Same setup works on VM and physical server
- **Infrastructure as Code** - Everything defined in docker-compose.yml
- **Resource Control** - Limit CPU/RAM per service
- **Security** - Services can't interfere with each other

### How It Works:
```
┌─────────────────────────────────────────┐
│         Your Home Server (Ubuntu)        │
├─────────────────────────────────────────┤
│              Docker Engine               │
├──────────┬──────────┬──────────┬────────┤
│  Plex    │ qBittor. │  Caddy   │ Other  │
│ Container│ Container│ Container│Services│
└──────────┴──────────┴──────────┴────────┘
```

Each container is like a lightweight virtual machine, but much more efficient!

---

## 🚀 Installation Steps

### Step 1: Update System Packages

**Why:** Ensure you have the latest security patches and package info.

**Command:**
```bash
sudo apt update
sudo apt upgrade -y
```

**What it does:**
- `apt update` - Downloads latest package lists from Ubuntu repos
- `apt upgrade -y` - Installs available updates (`-y` auto-confirms)

**Expected output:** List of packages updated, may take 1-5 minutes.

---

### Step 2: Install Docker Using Official Script

**Why:** Docker provides an official installation script that's easier and more reliable than manual installation. It automatically:
- Detects your Linux distribution
- Adds Docker's official repository
- Installs Docker Engine, CLI, and containerd
- Sets up everything correctly

**Alternative Methods (Not Recommended):**
- Ubuntu's `apt` package: Often outdated
- Manual installation: Complex and error-prone

**Command:**
```bash
# Download the official Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh

# Review the script (optional but recommended)
less get-docker.sh

# Run the installation
sudo sh get-docker.sh

# Clean up
rm get-docker.sh
```

**What each flag means:**
- `curl -fsSL`:
  - `-f` = Fail silently on server errors
  - `-s` = Silent mode (no progress bar)
  - `-S` = Show errors even in silent mode
  - `-L` = Follow redirects

**Expected output:**
```
# Executing docker install script, commit: <hash>
+ sudo -E sh -c apt-get update -qq >/dev/null
+ sudo -E sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
...
Client: Docker Engine - Community
 Version:           24.0.x
 API version:       1.43
 ...
```

**Time:** 2-5 minutes depending on internet speed.

---

### Step 3: Add Your User to the Docker Group

**Why:** By default, only root can run Docker commands. Adding your user to the `docker` group allows you to run Docker without `sudo`.

**Security Note:** Users in the `docker` group have root-equivalent privileges because they can run containers with root access. This is acceptable for a personal server where you're the only user.

**Command:**
```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Verify you were added
groups $USER
```

**What it does:**
- `usermod` - Modify user account
- `-aG docker` - Append (`a`) to Group (`G`) named `docker`
- `$USER` - Your username (automatically expands)

**Expected output:**
```
mykyta : mykyta adm cdrom sudo dip plugdev lxd docker
                                              ^^^^^^
                                         You should see docker
```

**IMPORTANT:** Changes take effect on next login.

### ⚠️ Special Note for VS Code Users

If you're using VS Code Remote SSH, simply typing `exit` in the terminal **won't work**!

**Why:** VS Code keeps a persistent server process running. When you close a terminal and open a new one, it reuses the same connection with old group memberships.

**VS Code-Specific Fix:**
1. `Ctrl+Shift+P`
2. Type: "Remote-SSH: Kill VS Code Server on Host"
3. Select your server
4. Reconnect to the server
5. Open new terminal - docker group will now be active

**Alternative:** Use Windows Terminal (or any SSH client) for the `exit` → reconnect. It creates a fresh connection properly.

**Quick Workaround:** Run `newgrp docker` in each VS Code terminal (but you'll need to do this every time).

---

**For Regular SSH (Windows Terminal, PuTTY, etc.):** You have 3 options:

**Option A: Log out and back in (Recommended)**
```bash
exit
# SSH back in
ssh mykyta@home-server
```

**Option B: Start new shell with new group**
```bash
newgrp docker
```

**Option C: Reboot the server**
```bash
sudo reboot
```

---

### Step 4: Verify Docker Installation

**Why:** Confirm Docker is installed correctly and you can run it without sudo.

**Commands:**
```bash
# Check Docker version
docker --version
# Should show: Docker version 24.0.x, build <hash>

# Check Docker Compose version
docker compose version
# Should show: Docker Compose version v2.x.x

# View Docker system info
docker info

# Check if Docker service is running
systemctl status docker
```

**Expected output for `docker info`:**
```
Client: Docker Engine - Community
 Version:    24.0.x
 Context:    default
 ...

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 ...
```

---

### Step 5: Test Docker with Hello World

**Why:** The official hello-world image verifies Docker can:
- Pull images from Docker Hub
- Create containers
- Run processes inside containers
- Display output

**Command:**
```bash
docker run hello-world
```

**What happens:**
1. Docker looks for `hello-world` image locally (not found)
2. Docker pulls the image from Docker Hub
3. Docker creates a container from the image
4. Docker runs the container
5. Container prints a message and exits

**Expected output:**
```
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c1ec31eb5944: Pull complete
Digest: sha256:...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

**Verify:**
```bash
# List running containers (should be empty - hello-world exits immediately)
docker ps

# List all containers (including stopped)
docker ps -a
# Should show the hello-world container with status "Exited"

# List downloaded images
docker images
# Should show hello-world image
```

**Clean up the test:**
```bash
# Remove the stopped container
docker rm $(docker ps -aq -f ancestor=hello-world)

# Remove the hello-world image (optional)
docker rmi hello-world
```

---

### Step 6: Docker Compose Plugin Verification

**Why:** Docker Compose is already installed! The official script installs it as a plugin.

**Two versions exist:**
- **V1** (old): Standalone binary `docker-compose` (with hyphen)
- **V2** (new): Plugin `docker compose` (space, no hyphen)

The script installs V2, which is the modern, supported version.

**Verify:**
```bash
# V2 (what you have)
docker compose version
# Docker Compose version v2.x.x

# V1 check (should not be installed)
docker-compose version
# Command 'docker-compose' not found (this is expected and fine)
```

**Note:** All modern tutorials use `docker compose` (V2). If you see old tutorials with `docker-compose`, just replace the hyphen with a space.

---

### Step 7: Install lazydocker (Optional but Recommended)

**Why:** lazydocker is a beautiful terminal UI that makes Docker management much easier:
- View all containers at once
- See logs in real-time
- Restart/stop/remove containers with hotkeys
- View resource usage
- Inspect container details
- Much faster than typing docker commands

**Command:**
```bash
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

**What it does:**
- Downloads the latest lazydocker binary
- Installs it to `/usr/local/bin/lazydocker`
- Makes it executable

**Verify:**
```bash
lazydocker --version
# lazydocker version x.x.x
```

**Usage:**
```bash
# Launch lazydocker
lazydocker

# Keyboard shortcuts (inside lazydocker):
# - ↑/↓      Navigate
# - [/]      Switch between tabs
# - Enter    View logs/details
# - r        Restart container
# - s        Stop container
# - d        Remove container
# - e        Execute shell in container
# - ?        Help menu
# - q        Quit
```

---

## 📋 Post-Installation Checklist

Run these commands to verify everything is working:

```bash
# 1. Docker version
docker --version
# ✅ Should show: Docker version 24.0.x

# 2. Docker Compose version
docker compose version
# ✅ Should show: Docker Compose version v2.x.x

# 3. Docker runs without sudo
docker ps
# ✅ Should show empty list (no permission errors)

# 4. Docker daemon is running
systemctl status docker
# ✅ Should show: Active: active (running)

# 5. lazydocker installed
lazydocker --version
# ✅ Should show version

# 6. User in docker group
groups
# ✅ Should include: docker
```

---

## 🎓 Docker Basics - What You Need to Know

### Key Concepts:

**Images** - Read-only templates (like a program installer)
```bash
docker images              # List all images
docker pull nginx          # Download nginx image
docker rmi nginx           # Remove nginx image
```

**Containers** - Running instances of images (like a running program)
```bash
docker ps                  # List running containers
docker ps -a               # List all containers (including stopped)
docker stop <container>    # Stop a container
docker start <container>   # Start a stopped container
docker rm <container>      # Remove a container
```

**Volumes** - Persistent data storage (survive container removal)
```bash
docker volume ls           # List volumes
docker volume create data  # Create a volume
docker volume rm data      # Remove a volume
```

**Networks** - How containers communicate
```bash
docker network ls          # List networks
docker network create app  # Create a network
```

### Important Commands:

```bash
# View container logs
docker logs <container-name>
docker logs -f <container-name>    # Follow logs (like tail -f)

# Execute command in running container
docker exec -it <container-name> bash     # Open bash shell
docker exec <container-name> ls -la       # Run single command

# View resource usage
docker stats                               # Live resource monitor

# Clean up unused resources
docker system prune                        # Remove stopped containers, unused networks
docker system prune -a                     # Also remove unused images
docker volume prune                        # Remove unused volumes
```

---

## 🔗 Useful Resources

- **Official Docker Docs:** https://docs.docker.com/
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **Docker Hub:** https://hub.docker.com/ (find container images)
- **lazydocker GitHub:** https://github.com/jesseduffield/lazydocker
- **LinuxServer.io:** https://www.linuxserver.io/ (best pre-built images for home servers)

---

## 💡 Pro Tips

1. **Always use official images** when possible (Docker Hub shows "Official Image" badge)
2. **Use LinuxServer.io images** for home server apps (Plex, qBittorrent, etc.) - they're better maintained
3. **Never run containers as root** unless necessary
4. **Use docker compose** for multi-container apps (easier than docker run)
5. **Tag your images** with specific versions, not `latest` (prevents surprise breakage)
6. **Use named volumes** instead of bind mounts when possible
7. **Learn lazydocker hotkeys** - saves tons of time

---

# Part 2: Quick Commands Reference

## 📦 Container Management

```bash
# List containers
docker ps              # Running containers
docker ps -a           # All containers (including stopped)

# Start/stop containers
docker start <name>    # Start stopped container
docker stop <name>     # Stop running container
docker restart <name>  # Restart container
docker rm <name>       # Remove stopped container
docker rm -f <name>    # Force remove (even if running)

# View logs
docker logs <name>           # View logs
docker logs -f <name>        # Follow logs (live)
docker logs --tail 50 <name> # Last 50 lines

# Execute commands inside container
docker exec -it <name> bash    # Open bash shell
docker exec -it <name> sh      # Open sh shell (if bash not available)
docker exec <name> ls -la      # Run single command
```

---

## 🖼️ Image Management

```bash
# List images
docker images          # All local images

# Pull images
docker pull nginx                    # Pull latest
docker pull nginx:1.25              # Pull specific version
docker pull linuxserver/plex        # Pull from specific user/org

# Remove images
docker rmi <image>     # Remove image
docker rmi -f <image>  # Force remove
```

---

## 🐳 Docker Compose Commands

```bash
# Start services
docker compose up                    # Start (foreground)
docker compose up -d                 # Start (background/detached)
docker compose up -d --build         # Rebuild and start

# Stop services
docker compose down                  # Stop and remove containers
docker compose down -v               # Also remove volumes
docker compose stop                  # Stop containers (keep them)

# View status
docker compose ps                    # List compose services
docker compose logs                  # View logs
docker compose logs -f               # Follow logs
docker compose logs -f <service>     # Follow logs for specific service

# Restart services
docker compose restart               # Restart all services
docker compose restart <service>     # Restart specific service

# Pull updates
docker compose pull                  # Pull latest images
docker compose up -d                 # Recreate containers with new images
```

---

## 🔍 Inspection & Debugging

```bash
# Inspect container
docker inspect <name>                # Full JSON details
docker inspect <name> | jq           # Formatted with jq

# Resource usage
docker stats                         # Live resource monitor (all containers)
docker stats <name>                  # Specific container stats

# Network inspection
docker network ls                    # List networks
docker network inspect <network>     # Network details

# Volume inspection
docker volume ls                     # List volumes
docker volume inspect <volume>       # Volume details
```

---

## 🧹 Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune
docker image prune -a                # Include unused images

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused (DANGEROUS)
docker system prune                  # Containers, networks, images
docker system prune -a               # More aggressive
docker system prune -a --volumes     # Include volumes (BE CAREFUL!)
```

---

## 📊 System Information

```bash
# Docker info
docker info                          # System-wide information
docker version                       # Version info

# Disk usage
docker system df                     # Show disk usage
docker system df -v                  # Verbose disk usage
```

---

## 🔐 Common Patterns for Home Server

### Run a quick test container
```bash
docker run -d --name nginx-test -p 8080:80 nginx
# Access at http://192.168.1.200:8080
docker rm -f nginx-test  # Clean up
```

### Run container with volume
```bash
docker run -d \
  --name myapp \
  -v /opt/homeserver/volumes/myapp:/data \
  myimage
```

### Run container with environment variables
```bash
docker run -d \
  --name myapp \
  -e VAR1=value1 \
  -e VAR2=value2 \
  myimage
```

### Run container with network
```bash
docker network create mynetwork
docker run -d --name myapp --network mynetwork myimage
```

---

## 🎯 lazydocker Shortcuts

```bash
# Launch
lazydocker

# Inside lazydocker:
# Tab       - Switch between sections
# ↑/↓       - Navigate
# Enter     - View details/logs
# [/]       - Previous/Next tab
# d         - Remove container/image
# e         - Execute shell
# r         - Restart
# s         - Stop
# m         - View container stats
# ?         - Help
# q         - Quit
```

---

## 📝 docker-compose.yml Template

```yaml
version: '3.8'

services:
  # Example service
  myservice:
    image: nginx:latest
    container_name: myservice
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./data:/usr/share/nginx/html
    environment:
      - MY_VAR=value
    networks:
      - mynetwork

  # Another service
  database:
    image: postgres:15
    container_name: postgres
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=changeme
    networks:
      - mynetwork

# Define networks
networks:
  mynetwork:
    driver: bridge

# Define volumes
volumes:
  postgres_data:
```

---

## 🔥 Most Used Commands (Daily)

```bash
# View all running services
docker ps

# View logs
docker logs -f <container-name>

# Restart a service
docker restart <container-name>

# Or with compose:
docker compose restart <service-name>

# Update and restart all services
cd /opt/homeserver
docker compose pull
docker compose up -d

# Quick cleanup
docker system prune
```

---

## ⚠️ Safety Tips

1. **Always backup before updates**
   ```bash
   cp docker-compose.yml docker-compose.yml.backup
   ```

2. **Test in dev first** - Don't update production directly

3. **Use specific versions** - Avoid `latest` tag in production
   ```yaml
   image: nginx:1.25  # Good
   image: nginx       # Bad (uses latest)
   ```

4. **Never commit secrets** - Use `.env` file
   ```bash
   echo ".env" >> .gitignore
   ```

5. **Check logs before removing** - `docker logs <container>`

---

**Quick Reference Legend:**
- `<name>` - Container name
- `<image>` - Image name
- `<service>` - Service name from docker-compose.yml
- `-d` - Detached (background)
- `-f` - Follow (live updates)
- `-a` - All
- `-v` - Volumes

---

# Part 3: Recovery Procedures

## What Happened When You Run `docker compose down`

When you run `docker compose down`, it:
1. ✅ Stops all containers (gracefully)
2. ✅ Removes all containers (they'll be recreated from images)
3. ✅ Removes all **internal** networks
4. ❌ **REMOVES EXTERNAL NETWORKS** (like `proxy` network)
5. ✅ **KEEPS YOUR DATA** (volumes are preserved!)

**Important:** Your data is safe! Volumes containing:
- Media files
- Databases
- Configurations
- Logs

...are all preserved and will be remounted when containers start.

---

## Quick Recovery (TL;DR)

```bash
# 1. Set permissions (if using monitoring services)
sudo chown -R 472:472 services/monitoring/grafana/data
sudo chown -R 10001:10001 services/monitoring/loki/data services/monitoring/promtail/positions

# 2. Start everything
docker compose up -d

# 3. Verify
docker compose ps
```

---

## Detailed Recovery Steps

### Step 1: Set Permissions (One-Time, if applicable)

```bash
# Grafana runs as user ID 472
sudo chown -R 472:472 services/monitoring/grafana/data

# Loki and Promtail run as user ID 10001
sudo chown -R 10001:10001 services/monitoring/loki/data
sudo chown -R 10001:10001 services/monitoring/promtail/positions

# Verify permissions
ls -la services/monitoring/grafana/data
ls -la services/monitoring/loki/data
ls -la services/monitoring/promtail/positions
```

**Expected output:**
```
drwxr-xr-x 2 472   472   ... grafana/data
drwxr-xr-x 2 10001 10001 ... loki/data
drwxr-xr-x 2 10001 10001 ... promtail/positions
```

---

### Step 2: Start Services

**Option A: Start Everything at Once (Simplest)**

```bash
docker compose up -d

# Docker Compose will:
# 1. Create all networks (proxy, monitoring, web, etc.)
# 2. Start services in dependency order
# 3. Wait for health checks

# Wait a moment for services to initialize
sleep 15

# Check status
docker compose ps
```

**Option B: Start Services Step-by-Step (More Control)**

```bash
# 1. Start reverse proxy (creates proxy network)
docker compose up -d caddy

# Wait for Caddy to be ready
sleep 5

# 2. Start tunnel
docker compose up -d cloudflared

# 3. Start monitoring stack (creates monitoring network)
docker compose up -d loki promtail grafana

# Wait for Loki to be healthy
sleep 10

# 4. Start media services
docker compose up -d jellyfin jellyseerr prowlarr radarr sonarr qbittorrent

# 5. Start web services
docker compose up -d hello-world

# 6. Check everything is running
docker compose ps
```

---

### Step 3: Verify Services Are Running

```bash
# Check all containers
docker compose ps

# Expected output: All services showing "Up" or "Up (healthy)"
```

**If any service shows "Restarting" or "Exited":**

```bash
# Check logs for that service
docker logs <service-name> --tail 50

# Common issues:
# - Permission errors (re-run chown commands)
# - Port conflicts (something else using the port)
# - Configuration errors (check config files)
```

---

### Step 4: Verify Networks

```bash
# List networks
docker network ls

# Verify containers are connected
docker network inspect proxy | jq '.[0].Containers | keys'
```

---

## Understanding Docker Compose Commands

### `docker compose stop`
**What it does:**
- Stops containers (gracefully)
- Keeps containers (can be started with `docker compose start`)
- Keeps networks
- Keeps volumes

**When to use:**
- Temporarily stopping services
- Quick restart needed
- Debugging

**Recovery:**
```bash
docker compose start
```

### `docker compose down`
**What it does:**
- Stops containers
- **Removes containers**
- **Removes networks** (including external ones if they're empty!)
- Keeps volumes (unless you use `--volumes` flag)

**When to use:**
- Cleaning up before major changes
- Resetting to fresh state
- Removing old container definitions

**Recovery:**
```bash
docker compose up -d
```

### `docker compose down --volumes` (DANGEROUS!)
**What it does:**
- Everything `down` does, plus:
- **DELETES ALL DATA VOLUMES**
- **PERMANENT DATA LOSS**

**When to use:**
- Complete reset (testing only!)
- **NEVER use in production without backups!**

**Recovery:**
```bash
# Can't recover deleted data!
# Would need to restore from backups
```

---

## Common Issues After Recovery

### Issue 1: "Network proxy not found"

**Cause:** External network was removed

**Fix:**
```bash
# Docker Compose will recreate it
docker compose up -d caddy

# Or create manually:
docker network create proxy
```

### Issue 2: "Permission denied" in container logs

**Cause:** Incorrect file ownership

**Fix:**
```bash
# Re-run permission commands
sudo chown -R 472:472 services/monitoring/grafana/data
sudo chown -R 10001:10001 services/monitoring/loki/data
sudo chown -R 10001:10001 services/monitoring/promtail/positions

# Restart affected service
docker compose restart grafana
docker compose restart loki
docker compose restart promtail
```

### Issue 3: Containers keep restarting

**Diagnosis:**
```bash
# Check logs
docker logs <container-name> --tail 50

# Check exit code
docker inspect <container-name> | jq '.[0].State'
```

**Common causes:**
- Configuration file syntax error
- Missing dependency (database, network)
- Port already in use
- Out of memory

**Fix:**
```bash
# Fix the underlying issue, then:
docker compose restart <service-name>
```

### Issue 4: Services can't connect to each other

**Cause:** Network connectivity issues

**Check:**
```bash
# Verify networks
docker network ls

# Check container is on correct network
docker inspect <container-name> | jq '.[0].NetworkSettings.Networks | keys'

# Test connectivity between containers
docker exec caddy ping -c 1 jellyfin
```

**Fix:**
```bash
# Reconnect to network
docker network connect proxy <container-name>

# Or restart service
docker compose restart <service-name>
```

---

## Prevention: Safe Workflow

### To restart services:
```bash
# Use restart (safer)
docker compose restart

# Or restart specific service
docker compose restart jellyfin
```

### To apply config changes:
```bash
# Restart affected service
docker compose restart caddy

# Or recreate service
docker compose up -d --force-recreate caddy
```

### To update images:
```bash
# Pull new images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Old containers are removed, data is preserved
```

### To completely reset (CAREFUL!):
```bash
# BACKUP FIRST!
tar -czf backup-$(date +%Y%m%d).tar.gz services/

# Then reset
docker compose down --volumes

# Restore from backup if needed
tar -xzf backup-20241122.tar.gz
```

---

## Quick Reference

| Command | What it does | Data safe? |
|---------|--------------|------------|
| `docker compose stop` | Stop containers | ✅ Yes |
| `docker compose start` | Start stopped containers | ✅ Yes |
| `docker compose restart` | Restart containers | ✅ Yes |
| `docker compose down` | Remove containers & networks | ✅ Yes (volumes kept) |
| `docker compose down --volumes` | Remove everything | ❌ NO! Data deleted |
| `docker compose up -d` | Start all services | ✅ Yes (creates from config) |
| `docker compose up -d --force-recreate` | Rebuild containers | ✅ Yes (volumes remounted) |

---

# Part 4: Troubleshooting

## Error: "permission denied while trying to connect to the Docker daemon"

**Cause:** User not in docker group OR need to re-login after adding to group.

**Solution:**
```bash
# Check if you're in docker group
groups

# If docker is missing, add yourself:
sudo usermod -aG docker $USER

# Then log out and back in:
exit
ssh mykyta@home-server

# Or use newgrp:
newgrp docker
```

---

## Error: "Cannot connect to the Docker daemon"

**Cause:** Docker service not running.

**Solution:**
```bash
# Check service status
systemctl status docker

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker
```

---

## Error: "Error response from daemon: Get https://registry-1.docker.io/v2/: net/http: request canceled"

**Cause:** Network/DNS issues.

**Solution:**
```bash
# Test internet connectivity
ping -c 4 google.com

# Test Docker Hub
ping -c 4 registry-1.docker.io

# Restart Docker
sudo systemctl restart docker
```

---

## Need Help?

If issues persist:

1. **Check logs:**
   ```bash
   docker compose logs <service-name> --tail 100
   ```

2. **Validate config:**
   ```bash
   docker compose config
   ```

3. **Check resource usage:**
   ```bash
   docker stats
   ```

4. **Restart specific service:**
   ```bash
   docker compose restart <service-name>
   ```

5. **Nuclear option (last resort):**
   ```bash
   # Backup first!
   tar -czf backup.tar.gz services/

   # Remove everything
   docker compose down --volumes

   # Restore from backup
   tar -xzf backup.tar.gz

   # Start fresh
   docker compose up -d
   ```

---

**Related Files:**
- [QOL_TOOLS_GUIDE.md](QOL_TOOLS_GUIDE.md) - Quality of life tools for Docker management
- [adding-services.md](adding-services.md) - Guide for adding new Docker services
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Essential commands cheat sheet
