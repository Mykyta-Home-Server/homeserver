# VM to Physical Server Migration Guide

**Document Purpose:** Step-by-step guide for migrating your home server from Hyper-V PoC VM to dedicated physical hardware.

**When to Use:** After completing your PoC testing and purchasing your dedicated server hardware.

**Estimated Time:** 1-2 hours (mostly Docker image downloads)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Backup Phase (VM)](#backup-phase-vm)
4. [Physical Server Preparation](#physical-server-preparation)
5. [Restoration Phase](#restoration-phase)
6. [Post-Migration Configuration](#post-migration-configuration)
7. [Verification & Testing](#verification--testing)
8. [Troubleshooting](#troubleshooting)
9. [Rollback Plan](#rollback-plan)

---

## Prerequisites

### What You Need

- ✅ Completed PoC VM with working services
- ✅ New physical server with Ubuntu Server 22.04 LTS installed
- ✅ Network connectivity on physical server
- ✅ SSH access to physical server (recommended)
- ✅ USB drive or network share for transfer (if not using git)
- ✅ 2-4 hours of maintenance window

### What You Should Have

Your PoC should have this structure in place:

```
/opt/homeserver/
├── docker-compose.yml        # All services defined
├── .env                       # Environment variables & secrets
├── .env.example              # Template (no actual secrets)
├── README.md                 # Your personal notes
├── caddy/
│   └── Caddyfile
├── cloudflare/
│   └── config.yml
├── mcp-server/
│   ├── requirements.txt
│   ├── server.py
│   └── config.json
├── telegram-bot/
│   ├── requirements.txt
│   └── bot.py
└── scripts/
    ├── backup.sh
    └── restore.sh
```

---

## Pre-Migration Checklist

### 1 Week Before Migration

- [ ] **Verify all services are working** in your VM
- [ ] **Document any custom configurations** not in files
- [ ] **Test your backup process** (practice run)
- [ ] **Update all Docker images** to latest stable versions
- [ ] **Clean up unused containers/volumes** to reduce backup size
- [ ] **Export service settings** that allow it (Plex preferences, etc.)
- [ ] **Take a Hyper-V checkpoint** (snapshot) as safety net

### 1 Day Before Migration

- [ ] **Stop accepting new data** (pause downloads, uploads)
- [ ] **Notify users** of planned downtime (if applicable)
- [ ] **Prepare physical server** (OS installed, network configured)
- [ ] **Verify git repo is up to date** (if using version control)
- [ ] **Check available disk space** on physical server

### Migration Day

- [ ] **Final VM checkpoint** before starting
- [ ] **Close all active connections** to services
- [ ] **Note current versions** of all containers

---

## Backup Phase (VM)

### Step 1: Prepare for Backup

```bash
# SSH into your VM (or use Hyper-V console)
ssh username@your-vm-ip

# Navigate to your homeserver directory
cd /opt/homeserver

# Stop all services gracefully
docker-compose down

# Verify all containers stopped
docker ps -a | grep homeserver
# Should show no running containers
```

**Why we stop services:**
- Ensures data consistency (no files being written during backup)
- Clean state for migration
- Prevents database corruption

### Step 2: Clean Up (Optional but Recommended)

```bash
# Remove unused images to reduce backup size
docker image prune -a

# Remove unused volumes (BE CAREFUL - verify nothing important)
docker volume ls
# Only remove volumes you're certain are unused

# Check backup size estimate
du -sh /opt/homeserver
```

### Step 3: Create Backup Archive

#### Option A: Full Backup (Recommended for First Migration)

```bash
# Create comprehensive backup
sudo tar -czf ~/homeserver-full-backup.tar.gz \
  /opt/homeserver \
  /etc/docker/daemon.json \
  /etc/systemd/system/docker.service.d/ \
  ~/.docker

# Verify backup was created
ls -lh ~/homeserver-full-backup.tar.gz

# Create checksum for integrity verification
sha256sum ~/homeserver-full-backup.tar.gz > ~/homeserver-backup.sha256
```

#### Option B: Configuration-Only Backup (Faster)

```bash
# Backup only configurations (Docker will re-download images)
sudo tar -czf ~/homeserver-config-backup.tar.gz \
  --exclude='/opt/homeserver/volumes/*/cache' \
  --exclude='/opt/homeserver/volumes/*/logs' \
  /opt/homeserver

# This is much smaller but requires re-downloading all Docker images
```

### Step 4: Backup Persistent Data Separately

```bash
# Important: Media and databases should be backed up separately
# They're large and may need special handling

# Example: Backup Plex database
sudo tar -czf ~/plex-data-backup.tar.gz /opt/homeserver/volumes/plex

# Example: Backup qBittorrent data
sudo tar -czf ~/qbittorrent-data-backup.tar.gz /opt/homeserver/volumes/qbittorrent

# List all volumes for reference
ls -la /opt/homeserver/volumes/
```

### Step 5: Transfer Backups

#### Option A: Using Git (Recommended)

```bash
# If you've been using version control
cd /opt/homeserver

# Commit any final changes
git add .
git commit -m "Final VM state before migration"
git push origin main

# Tag this state
git tag -a "vm-final-state" -m "Last working state on VM before migration"
git push origin vm-final-state

# Data volumes still need separate transfer
# Copy to network share or USB
```

#### Option B: Using SCP (Network Transfer)

```bash
# Transfer to physical server over network
scp ~/homeserver-full-backup.tar.gz username@physical-server-ip:~/
scp ~/homeserver-backup.sha256 username@physical-server-ip:~/

# Or transfer to your Windows machine first
scp ~/homeserver-full-backup.tar.gz your-windows-username@windows-ip:/path/to/safe/location/
```

#### Option C: Using USB Drive

```bash
# Mount USB drive
sudo mkdir /mnt/usb
sudo mount /dev/sdb1 /mnt/usb  # Adjust device name as needed

# Copy backup
sudo cp ~/homeserver-full-backup.tar.gz /mnt/usb/
sudo cp ~/homeserver-backup.sha256 /mnt/usb/

# Safely unmount
sudo umount /mnt/usb
```

### Step 6: Verify Backup Integrity

```bash
# Verify the archive isn't corrupted
tar -tzf ~/homeserver-full-backup.tar.gz > /dev/null && echo "Backup is valid" || echo "Backup is corrupted!"

# Verify checksum
sha256sum -c ~/homeserver-backup.sha256
```

**⚠️ CRITICAL:** Do not proceed until backup is verified!

---

## Physical Server Preparation

### Step 1: Fresh Ubuntu Server Installation

**Assumptions:**
- Ubuntu Server 22.04 LTS installed
- Network configured (static IP recommended)
- SSH enabled
- You have sudo access

**Verify installation:**

```bash
# SSH into your physical server
ssh username@physical-server-ip

# Check OS version
lsb_release -a
# Should show Ubuntu 22.04.x LTS

# Check network connectivity
ping -c 4 google.com

# Check available disk space
df -h
# Ensure you have enough space for your data
```

### Step 2: Initial Server Hardening

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  ufw

# Configure firewall (we'll use Cloudflare Tunnel, so minimal ports)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Create homeserver directory with proper permissions
sudo mkdir -p /opt/homeserver
sudo chown -R $USER:$USER /opt/homeserver
```

### Step 3: Install Docker

```bash
# Install Docker using official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (avoid using sudo with docker)
sudo usermod -aG docker $USER

# Install Docker Compose V2
sudo apt install -y docker-compose-plugin

# IMPORTANT: Log out and back in for group changes to take effect
exit
# SSH back in
ssh username@physical-server-ip

# Verify Docker installation
docker --version
docker compose version

# Test Docker works without sudo
docker run hello-world
```

### Step 4: Configure Docker (Optional Performance Tweaks)

```bash
# Create Docker daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker to apply changes
sudo systemctl restart docker
sudo systemctl enable docker
```

---

## Restoration Phase

### Step 1: Transfer Backup to Physical Server

**If using Git:**

```bash
cd /opt/homeserver
git clone git@github.com:yourusername/homeserver-config.git .

# Verify files are present
ls -la
```

**If using backup archive:**

```bash
# If backup is on your machine, transfer it
# (from your Windows machine or wherever you stored it)

# On physical server, restore from archive
cd ~
# Verify checksum first!
sha256sum -c homeserver-backup.sha256

# Extract backup
sudo tar -xzf homeserver-full-backup.tar.gz -C /

# Fix permissions
sudo chown -R $USER:$USER /opt/homeserver
```

### Step 2: Restore Environment Variables

```bash
cd /opt/homeserver

# Verify .env file exists
ls -la .env

# IMPORTANT: Review and update any environment variables that might change
# Example: Host IP addresses, paths, etc.
nano .env

# Common variables to check:
# - PUID / PGID (user/group IDs might differ)
# - TZ (timezone)
# - Local IP addresses
# - Volume paths (should be the same if you used /opt/homeserver structure)
```

### Step 3: Verify Docker Compose Configuration

```bash
cd /opt/homeserver

# Verify docker-compose.yml syntax
docker compose config

# This should show your parsed configuration
# If there are errors, fix them before proceeding
```

### Step 4: Pull Docker Images

```bash
# Pull all required images (may take 30-60 minutes depending on internet)
docker compose pull

# Monitor progress
# You'll see each service image being downloaded
```

### Step 5: Start Services

```bash
# Start all services in detached mode
docker compose up -d

# Watch logs for any errors
docker compose logs -f

# Press Ctrl+C to exit logs when satisfied

# Check all containers are running
docker compose ps

# Should show all services as "Up" or "healthy"
```

---

## Post-Migration Configuration

### Step 1: Re-authenticate Cloudflare Tunnel

**Why needed:** Cloudflare Tunnel binds to machine ID, which changed.

```bash
# Navigate to cloudflare directory
cd /opt/homeserver/cloudflare

# Login to Cloudflare (will open browser)
cloudflared tunnel login

# Verify your tunnel exists
cloudflared tunnel list

# If tunnel already exists, just restart the container
docker compose restart cloudflare-tunnel

# If you need to recreate the tunnel:
# cloudflared tunnel create homeserver
# Update config.yml with new tunnel ID
# Update DNS records in Cloudflare dashboard
```

**Reference:** See `architecture.md` for detailed Cloudflare Tunnel setup.

### Step 2: Verify Static IP Configuration (If Used)

```bash
# If you assigned static IPs to containers, verify they're available
docker network inspect homeserver_default

# Check for IP conflicts
# Update docker-compose.yml if IP ranges conflict
```

### Step 3: Update System-Specific Configurations

```bash
# Check if any paths need updating
grep -r "/home/oldusername" /opt/homeserver/

# Update cron jobs if you created any
crontab -l

# If you had scheduled backups, recreate them
crontab -e
```

### Step 4: Restart All Services

```bash
# Full restart to ensure all changes take effect
cd /opt/homeserver
docker compose down
docker compose up -d

# Wait 1-2 minutes for all services to initialize
sleep 120

# Check status
docker compose ps
```

---

## Verification & Testing

### Checklist: Verify Each Service

```bash
# General health check
docker compose ps
# All should show "healthy" or "running"

# Check logs for errors
docker compose logs | grep -i error
docker compose logs | grep -i fatal

# If specific service has issues:
docker compose logs <service-name>
```

### Test 1: Internal Network Access

```bash
# From another machine on your network, test internal access

# Test Plex (example)
curl http://physical-server-ip:32400/web

# Test if Caddy is responding
curl http://physical-server-ip:80
# Should get response or redirect to HTTPS
```

### Test 2: Reverse Proxy (Caddy)

```bash
# Check Caddy is running
docker exec -it caddy caddy version

# View Caddy logs
docker compose logs caddy

# Test internal reverse proxy
curl http://localhost
```

### Test 3: Cloudflare Tunnel

```bash
# Check tunnel status
docker compose logs cloudflare-tunnel | tail -20

# Look for "Connection established" messages

# From external network (use your phone's data), access:
# https://plex.yourdomain.com
# https://qbittorrent.yourdomain.com
# etc.
```

### Test 4: Application Data Integrity

- [ ] **Plex:** Login, verify libraries are intact
- [ ] **qBittorrent:** Verify torrents are present (may need to recheck)
- [ ] **Minecraft:** Verify world data loaded
- [ ] **Other services:** Check service-specific data

### Test 5: MCP Server & Telegram Bot

```bash
# Test MCP server
curl http://localhost:3000/health
# Or whatever health check endpoint you defined

# Check Telegram bot
# Send a message to your bot
# Verify it responds correctly

# Check bot logs
docker compose logs telegram-bot
```

### Test 6: Automated Tasks

```bash
# If you set up cron jobs, verify they're scheduled
crontab -l

# Check system logs for any errors
journalctl -xe
```

---

## Troubleshooting

### Issue: Container Won't Start

**Symptoms:** `docker compose ps` shows container as "Exited" or "Restarting"

**Diagnosis:**

```bash
# Check specific container logs
docker compose logs <container-name>

# Check for port conflicts
sudo netstat -tulpn | grep LISTEN

# Check for volume permission issues
ls -la /opt/homeserver/volumes/<service-name>/
```

**Solutions:**

```bash
# Fix volume permissions
sudo chown -R $USER:$USER /opt/homeserver/volumes/<service-name>

# Or use PUID/PGID in .env
# Edit .env and set:
PUID=1000  # Your user ID (run: id -u)
PGID=1000  # Your group ID (run: id -g)

# Restart service
docker compose up -d <service-name>
```

### Issue: Cloudflare Tunnel Not Connecting

**Symptoms:** Can't access services from external network

**Diagnosis:**

```bash
# Check tunnel logs
docker compose logs cloudflare-tunnel

# Verify tunnel exists in Cloudflare dashboard
cloudflared tunnel list

# Check DNS records in Cloudflare
```

**Solutions:**

```bash
# Re-authenticate
cloudflared tunnel login

# Verify config.yml has correct tunnel ID
cat /opt/homeserver/cloudflare/config.yml

# Restart tunnel
docker compose restart cloudflare-tunnel

# If all else fails, recreate tunnel (see Post-Migration Step 1)
```

### Issue: "Cannot Connect to Docker Daemon"

**Symptoms:** `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Solution:**

```bash
# Verify Docker is running
sudo systemctl status docker

# Start Docker if stopped
sudo systemctl start docker

# Verify you're in docker group
groups $USER
# Should show "docker" in the list

# If not in docker group:
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Out of Disk Space

**Symptoms:** Services failing, container won't start

**Diagnosis:**

```bash
# Check disk usage
df -h

# Check Docker disk usage
docker system df
```

**Solution:**

```bash
# Clean up Docker resources
docker system prune -a --volumes

# WARNING: This removes ALL unused containers, images, and volumes
# Make sure you have backups first!

# Or selectively remove:
docker image prune -a  # Remove unused images
docker volume prune    # Remove unused volumes
```

### Issue: Service Data Missing or Corrupted

**Symptoms:** Plex libraries empty, qBittorrent torrents missing, etc.

**Diagnosis:**

```bash
# Check if volumes are mounted correctly
docker inspect <container-name> | grep -A 10 "Mounts"

# Check volume contents
ls -la /opt/homeserver/volumes/<service-name>/
```

**Solution:**

```bash
# Stop service
docker compose stop <service-name>

# Restore data from backup
sudo tar -xzf ~/<service>-data-backup.tar.gz -C /

# Fix permissions
sudo chown -R $USER:$USER /opt/homeserver/volumes/<service-name>

# Restart service
docker compose up -d <service-name>
```

### Issue: Network Connectivity Problems

**Symptoms:** Containers can't reach internet, can't talk to each other

**Diagnosis:**

```bash
# Check Docker networks
docker network ls
docker network inspect homeserver_default

# Test internet from container
docker exec -it <container-name> ping -c 4 google.com

# Check firewall rules
sudo ufw status
```

**Solution:**

```bash
# Recreate Docker network
docker compose down
docker network prune
docker compose up -d

# Check firewall isn't blocking Docker
sudo ufw status
# Ensure Docker interfaces are allowed
```

---

## Rollback Plan

**If migration fails catastrophically:**

### Option 1: Keep VM Running (Recommended During Migration)

- Don't delete your Hyper-V VM until physical server is confirmed working
- Can fall back to VM immediately
- Gives you time to troubleshoot physical server

### Option 2: Restore from Backup

```bash
# On physical server, if you need to start over
cd /opt/homeserver
docker compose down
sudo rm -rf /opt/homeserver/*

# Re-extract backup
sudo tar -xzf ~/homeserver-full-backup.tar.gz -C /
sudo chown -R $USER:$USER /opt/homeserver

# Try again
docker compose up -d
```

### Option 3: Restore to VM

```bash
# If physical server has hardware issues
# Boot up your Hyper-V VM from checkpoint
# All data is intact, services come back online immediately
```

---

## Post-Migration Cleanup

**Once everything is verified working (wait 1-2 weeks):**

```bash
# On VM (if you want to reclaim space)
# Delete backup files
rm ~/homeserver-full-backup.tar.gz
rm ~/homeserver-backup.sha256

# On physical server
# Delete transferred backup
rm ~/homeserver-full-backup.tar.gz

# You can now delete or power off the Hyper-V VM
# Recommendation: Keep VM powered off for 1 month as safety net
# Then delete if physical server is stable
```

---

## Best Practices for Easier Future Migrations

### During Your PoC Development

1. **Use Git from Day One**
   ```bash
   cd /opt/homeserver
   git init
   git add .
   git commit -m "Initial setup"
   ```

2. **Never Hardcode Values**
   - Always use `.env` files
   - Use environment variables in docker-compose.yml
   - Document what each variable does

3. **Keep Data Separate from Config**
   - Configuration: `/opt/homeserver/*.yml`
   - Data: `/opt/homeserver/volumes/`
   - Easy to backup separately

4. **Document Custom Changes**
   - Keep a `CHANGELOG.md` or `README.md`
   - Note anything you did outside of config files
   - Future you will thank you

5. **Test Backups Regularly**
   ```bash
   # Create a backup script
   nano /opt/homeserver/scripts/backup.sh
   # Run it weekly
   # Verify you can restore from it
   ```

6. **Use Consistent Paths**
   - Always use `/opt/homeserver` as base
   - Avoid absolute paths that reference machine-specific locations
   - Use relative paths in docker-compose.yml

### Example Backup Script

```bash
#!/bin/bash
# /opt/homeserver/scripts/backup.sh

BACKUP_DIR="$HOME/homeserver-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/homeserver-backup-$TIMESTAMP.tar.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Stop services for consistent backup
cd /opt/homeserver
docker compose down

# Create backup
sudo tar -czf $BACKUP_FILE \
  --exclude='/opt/homeserver/volumes/*/cache' \
  --exclude='/opt/homeserver/volumes/*/logs' \
  /opt/homeserver

# Restart services
docker compose up -d

# Create checksum
sha256sum $BACKUP_FILE > $BACKUP_FILE.sha256

# Keep only last 7 backups
ls -t $BACKUP_DIR/homeserver-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: $BACKUP_FILE"
```

---

## Success Criteria

Your migration is successful when:

- ✅ All containers show "healthy" status
- ✅ Services accessible via subdomains externally
- ✅ Internal network access works
- ✅ Application data intact (libraries, downloads, etc.)
- ✅ MCP server responds to requests
- ✅ Telegram bot processes commands
- ✅ No errors in logs (minor warnings ok)
- ✅ Performance meets or exceeds VM performance
- ✅ Automated tasks run on schedule
- ✅ Backups working on new server

---

## Timeline Reference

**Realistic migration timeline:**

| Phase | Estimated Time | Can Run in Background? |
|-------|----------------|------------------------|
| Backup VM | 15-30 minutes | No |
| Transfer files | 10-60 minutes | Yes |
| Prepare physical server | 20-30 minutes | No |
| Install Docker | 10 minutes | No |
| Restore configuration | 5 minutes | No |
| Pull Docker images | 30-90 minutes | Yes |
| Start services | 5 minutes | No |
| Cloudflare re-auth | 5 minutes | No |
| Testing & verification | 30-60 minutes | No |

**Total:** 2-5 hours depending on internet speed and data size

---

## Additional Resources

- **Docker Documentation:** https://docs.docker.com/
- **Docker Compose Migration:** https://docs.docker.com/compose/migrate/
- **Ubuntu Server Guide:** https://ubuntu.com/server/docs
- **Cloudflare Tunnel Docs:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Caddy Documentation:** https://caddyserver.com/docs/

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-11-20 | Initial migration guide created |

---

## Notes Section (For Your Use)

Use this space during migration to track:
- Issues encountered:
- Solutions that worked:
- Things to improve for next time:
- Performance differences noted:

---

**Remember:** Take your time, verify each step, and don't delete your VM until you're 100% confident the physical server is stable!
