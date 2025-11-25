# Home Server PoC - Session Status & Notes

**Last Updated:** 2025-11-22
**Current Phase:** Service Deployment - First Public Website Live
**Status:** 🟢 Production-Ready Infrastructure Deployed

---

## Quick Reference

| Item | Value |
|------|-------|
| **VM Name** | Ubuntu-HomeServer-PoC |
| **Hostname** | home-server |
| **Host OS** | Windows Pro with Hyper-V |
| **Guest OS** | Ubuntu Server 22.04 LTS |
| **Username** | mykyta |
| **SSH Connection** | `mykyta@home-server` (Tailscale) or `mykyta@192.168.1.200` |
| **Project Directory** | `/opt/homeserver` |
| **VM IP Address** | 192.168.1.200 (Bridged - External Switch) |
| **Home Network** | 192.168.1.x/24 |
| **Domain** | mykyta-ryasny.dev |
| **Public Website** | https://mykyta-ryasny.dev ✅ LIVE |
| **Cloudflare Tunnel** | 07fbc124-6f0e-40c5-b254-3a1bdd98cf3c |
| **SSL Mode** | Full (Cloudflare Origin Certificates) |

---

## Hardware Specifications

### Physical Development Machine
- **CPU:** AMD Ryzen 7 7800X3D (8 cores)
- **RAM:** 64GB DDR5
- **Storage:** 2TB

### Virtual Machine (Hyper-V)
- **Generation:** 2 (UEFI)
- **CPU:** 6 virtual cores (allocated from 8 physical)
- **RAM:** 16GB (dedicated, no dynamic memory)
- **Storage:** 200GB (dynamic VHDX)
- **Network:** External Virtual Switch (Bridged) ✅ **CONFIGURED**
- **Secure Boot:** Disabled (for Linux compatibility)
- **Hostname:** home-server

---

## Completed Steps ✅

### 1. PoC Planning & Tool Selection
- ✅ Chose Hyper-V over WSL2/VirtualBox for accurate networking simulation
- ✅ Decided on VM resource allocation (6 cores, 16GB RAM, 200GB disk)
- ✅ Created comprehensive migration guide: `.claude/migration_guide.md`

### 2. Hyper-V VM Creation
- ✅ Enabled Hyper-V on Windows Pro
- ✅ Downloaded Ubuntu Server 22.04 LTS ISO
- ✅ Created VM with proper specifications
- ✅ Configured VM settings:
  - Disabled Secure Boot (Linux compatibility)
  - Set 6 virtual processors
  - Configured 16GB static RAM
  - Initially used "Default Switch" (NAT)

### 3. Ubuntu Server Installation
- ✅ Installed Ubuntu Server 22.04 LTS
- ✅ Selected standard installation (not minimized)
- ✅ Configured disk with simple partitioning (no LVM)
- ✅ Created user account: `mykyta`
- ✅ Installed OpenSSH server during installation
- ✅ Completed first boot and login

### 4. Initial System Configuration
- ✅ Verified VM resources (6 cores, 16GB RAM, ~197GB disk)
- ✅ Confirmed internet connectivity
- ✅ Tested SSH access from Windows

### 5. Terminal Setup Research
- ✅ Evaluated terminal options (Windows Terminal, MobaXterm, VS Code Remote SSH)
- ✅ Decided on: Windows Terminal + VS Code Remote SSH combination
- ✅ Planned for Claude integration in VM

### 6. Network Configuration ✅
- ✅ Created External Virtual Switch in Hyper-V Manager
- ✅ Configured VM to use External Switch (Bridged networking)
- ✅ VM now on home network: 192.168.1.200
- ✅ Hostname set to: home-server
- ✅ SSH accessible via: mykyta@home-server or mykyta@192.168.1.200

### 7. Quality of Life Tools Installation ✅
- ✅ ZSH + Oh My Zsh with plugins (syntax highlighting, autosuggestions)
- ✅ File navigation tools (bat, exa, fzf, tree, ripgrep)
- ✅ System monitoring (btop, htop, ncdu, glances)
- ✅ Git tools (lazygit, tig)
- ✅ Development tools (tmux, tldr, jq)
- ✅ VS Code settings configured for ZSH integration
- ✅ Created comprehensive guides:
  - `QOL_TOOLS_GUIDE.md` - Tool usage reference
  - `ZSH_SETUP_SOLUTION.md` - ZSH troubleshooting
  - `setup-quality-of-life.sh` - Installation script

### 8. Docker Installation ✅
- ✅ Installed Docker Engine (latest stable)
- ✅ Installed Docker Compose V2 (plugin)
- ✅ Added user to docker group
- ✅ Verified docker runs without sudo
- ✅ Installed lazydocker (Docker TUI)
- ✅ Tested with hello-world container
- ✅ Created comprehensive guides:
  - `DOCKER_INSTALLATION_GUIDE.md` - Complete installation guide
  - `DOCKER_QUICK_COMMANDS.md` - Command reference
- ✅ **Key Learning:** VS Code Remote SSH requires special handling for group changes

---

## ✅ Foundation Phase Complete!

**🎉 Development Environment Ready!**

All foundational tools are installed and configured:
- ✅ Ubuntu Server 22.04 LTS with bridged networking
- ✅ ZSH with Oh My Zsh and productivity tools
- ✅ Docker + Docker Compose + lazydocker
- ✅ Git repository initialized
- ✅ VS Code Remote SSH configured
- ✅ Comprehensive documentation created

**Current Capabilities:**
- Run containers with Docker
- Manage multi-container apps with Docker Compose
- Visual Docker management with lazydocker
- Enhanced terminal experience with ZSH
- Git version control for Infrastructure as Code

---

## 📋 Next Phase: Service Deployment

### Option A: Deploy Reverse Proxy First (Recommended)
Set up Caddy reverse proxy with automatic HTTPS:
1. Create docker-compose.yml for Caddy
2. Configure Caddyfile for subdomain routing
3. Test with simple service (whoami or nginx)
4. Set up Cloudflare Tunnel for external access

### Option B: Deploy First Application
Start with a core service:
1. Plex Media Server (media streaming)
2. qBittorrent (download manager)
3. Homepage (dashboard)

### Option C: Infrastructure Setup
Prepare for multiple services:
1. Create directory structure for each service
2. Set up shared Docker network
3. Create base docker-compose.yml template
4. Plan subdomain structure

---

## Next Steps (After Network Config)

### Immediate (This Session)
1. [ ] **Update system packages**
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo apt autoremove -y
   ```

2. [ ] **Set up SSH key authentication** (optional but recommended)
   - Generate SSH key on Windows
   - Copy to VM with `ssh-copy-id`
   - Test passwordless login

3. [ ] **Install Docker**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   # Log out and back in
   docker --version
   docker run hello-world
   ```

4. [ ] **Install Docker Compose V2**
   ```bash
   sudo apt install -y docker-compose-plugin
   docker compose version
   ```

5. [ ] **Set up project directory structure**
   ```bash
   sudo mkdir -p /opt/homeserver
   sudo chown -R $USER:$USER /opt/homeserver
   cd /opt/homeserver
   mkdir -p {caddy,cloudflare,mcp-server,telegram-bot,scripts,volumes}
   ```

6. [ ] **Initialize Git repository**
   ```bash
   cd /opt/homeserver
   git init
   git config --global user.name "Mykyt"
   git config --global user.email "your-email@example.com"
   # Create .gitignore for .env and volumes/
   ```

7. [ ] **Test first container deployment**
   - Create simple docker-compose.yml
   - Deploy nginx test container
   - Verify access from Windows browser

### Short-term (Next Sessions)
- [ ] Configure Windows Terminal profile with reserved IP
- [ ] Set up VS Code Remote SSH
- [ ] Install Claude Code CLI or Continue extension
- [ ] Deploy Caddy reverse proxy
- [ ] Configure Cloudflare Tunnel
- [ ] Deploy first real service (Plex or qBittorrent)

### Medium-term
- [ ] Build MCP server for automation
- [ ] Create Telegram bot integration
- [ ] Set up automated backups
- [ ] Create monitoring dashboard

---

## Key Decisions & Rationale

### Network: Bridged vs NAT
**Decision:** Use External Virtual Switch (Bridged Networking)

**Why:**
- VM appears as real device on home network (realistic for production)
- Can reserve IP in router DHCP (stable configuration)
- Accessible from any device on network (better for testing)
- Same behavior as future physical server
- Required for proper reverse proxy and Cloudflare Tunnel testing

**Trade-off:** Slightly more complex than NAT, but essential for realistic PoC

---

### IP Assignment: DHCP Reservation vs Static IP on VM
**Decision:** DHCP Reservation in Router

**Why:**
- Centralized management (all static IPs in one place)
- Easy to change if needed (just update router)
- Standard practice for production servers
- Survives VM reconfiguration

**Note:** For VM (PoC), static IP on VM would also work, but learning router-based approach prepares for physical server.

---

### Terminal Setup: Windows Terminal + VS Code Remote SSH
**Decision:** Use combination approach, not just one tool

**Why:**
- Windows Terminal: Quick SSH access, running commands, monitoring
- VS Code Remote SSH: File editing, development work, Claude integration
- Both free, Microsoft-supported, industry standard
- Best of both worlds (speed + powerful editing)

---

### Docker: Official Script vs Package Manager
**Decision:** Use official Docker installation script

**Why:**
- Most up-to-date Docker version
- Official method recommended by Docker
- Consistent across different Linux distributions
- Same method we'll use on physical server

---

### Directory Structure: `/opt/homeserver`
**Decision:** All configurations in `/opt/homeserver`

**Why:**
- Standard location for optional software on Linux
- Easy to backup (one directory)
- Easy to migrate (copy entire directory)
- Clean separation from system files
- Matches Infrastructure as Code principle

---

## Commands Reference

### Network Diagnostics
```bash
# Check IP address
ip addr show eth0
hostname -I

# Check gateway/routing
ip route | grep default

# Check MAC address
ip link show eth0

# Test connectivity
ping -c 4 google.com
ping -c 4 192.168.1.1  # Router

# Renew DHCP lease
sudo dhclient -r eth0  # Release
sudo dhclient eth0     # Renew
```

### System Information
```bash
# OS version
lsb_release -a

# CPU cores
nproc

# RAM
free -h

# Disk space
df -h

# System info
uname -a
```

### Docker Commands (For Later)
```bash
# Check Docker status
docker --version
docker compose version
docker ps

# Run test container
docker run hello-world

# View logs
docker logs <container-name>
docker compose logs

# Start/stop services
docker compose up -d
docker compose down
```

---

## Troubleshooting Notes

### Issue: VM Has 172.x.x.x IP Instead of 192.168.x.x
**Cause:** Using Hyper-V Default Switch (NAT) instead of External Switch (Bridged)

**Solution:**
1. Create External Virtual Switch in Hyper-V Manager
2. Change VM network adapter to External Switch
3. Restart VM
4. Verify new IP: `ip addr show eth0`

---

### Issue: Lost Internet After Creating External Switch
**Cause:** Bridge interfering with host network

**Solution:**
1. Ensure "Allow management OS to share adapter" is checked
2. Disable/re-enable network adapter on Windows host
3. Verify External Switch is connected to correct physical adapter

---

### Issue: Can't SSH After IP Change
**Cause:** SSH known_hosts file has old IP fingerprint

**Solution:**
```powershell
# On Windows, remove old entry
ssh-keygen -R 172.24.96.5  # Old IP
ssh-keygen -R 192.168.1.100  # New IP (if needed)
```

---

## Documentation Files

| File | Purpose | Status |
|------|---------|--------|
| `CLAUDE.md` | Core instructions for Claude about project | ✅ Created |
| `.claude/migration_guide.md` | VM to physical server migration steps | ✅ Created |
| `.claude/architecture.md` | System architecture documentation | ✅ Created |
| `.claude/technical_specs.md` | Technical specifications | ✅ Created |
| `.claude/api_documentation.md` | API documentation | ✅ Created |
| `.claude/code_examples.md` | Code examples and templates | ✅ Created |
| `.claude/docs/adding-services.md` | Complete guide for adding new services | ✅ Created |
| `SESSION_STATUS.md` | This file - current progress tracking | ✅ Updated |
| `/opt/homeserver/docker-compose.yml` | Service definitions (caddy, cloudflared, hello-world) | ✅ Created |
| `/opt/homeserver/services/caddy/Caddyfile` | Master Caddy configuration | ✅ Created |
| `/opt/homeserver/services/caddy/README.md` | Caddy quick reference | ✅ Created |
| `/opt/homeserver/services/caddy/sites/_template.caddy` | Template for new services | ✅ Created |
| `/opt/homeserver/services/caddy/sites/hello-world.caddy` | Hello World service config | ✅ Created |
| `/opt/homeserver/services/cloudflared/config.yml` | Cloudflare Tunnel configuration | ✅ Created |
| `/opt/homeserver/.gitignore` | Git ignore rules | ⏳ To create |
| `/opt/homeserver/README.md` | Project overview in VM | ⏳ To create |
| `/opt/homeserver/.env.example` | Environment variables template | ⏳ To create |

---

## Resources & References

### Official Documentation
- **Ubuntu Server Guide:** https://ubuntu.com/server/docs
- **Docker Documentation:** https://docs.docker.com/
- **Docker Compose:** https://docs.docker.com/compose/
- **Hyper-V Documentation:** https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/

### Project-Specific
- **Caddy Reverse Proxy:** https://caddyserver.com/docs/
- **Cloudflare Tunnel:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **MCP Protocol:** (to be added)
- **Telegram Bot API:** (to be added)

---

## Notes for Future Claude Sessions

### When Starting a New Chat:
```
"Read CLAUDE.md and SESSION_STATUS.md to understand the project.
Current status: [describe where you are]
I need help with: [specific task]"
```

### Context You Should Know:
- This is a learning project - explain WHY, not just HOW
- User prefers detailed explanations with references
- Always follow Infrastructure as Code principles
- Security first (no exposed ports, use Cloudflare Tunnel)
- Everything should be reproducible and documented

### Current Architecture (Planned):
```
Internet
   ↕
Cloudflare Tunnel (no exposed ports)
   ↕
Caddy Reverse Proxy (automatic HTTPS)
   ↕
Docker Containers (isolated services)
   ↕
MCP Server (natural language control)
   ↕
Telegram Bot (user interface)
```

---

## Git Workflow

### Initial Setup (To Do)
```bash
cd /opt/homeserver
git init
git add .
git commit -m "Initial homeserver structure"

# Create GitHub repo (private recommended)
git remote add origin git@github.com:yourusername/homeserver-config.git
git push -u origin main
```

### Regular Commits
```bash
# After each major change
git add .
git commit -m "Descriptive message about what changed"
git push
```

### Best Practices
- Commit after each working configuration change
- Use descriptive commit messages
- Never commit `.env` files with secrets
- Tag major milestones: `git tag -a v0.1-poc-complete -m "PoC VM fully configured"`

---

## Questions to Address in Future Sessions

1. **Claude Integration:**
   - Install Claude Code CLI in VM?
   - Or use VS Code with Continue extension?
   - Or both?

2. **Services Priority:**
   - Which service to deploy first?
   - Plex for media?
   - qBittorrent for downloads?
   - Or start with simpler service for learning?

3. **Domain Setup:**
   - Purchase domain now or later?
   - Which domain registrar?
   - Cloudflare for DNS?

4. **Backup Strategy:**
   - Automated backup scripts?
   - How often to backup?
   - Where to store backups?

---

## Session Log

### Session 1 - 2024-11-20
**Duration:** ~2 hours
**Focus:** VM creation, initial setup, network architecture planning

**Accomplishments:**
- Created comprehensive migration guide
- Set up Hyper-V VM with proper specs
- Installed Ubuntu Server 22.04
- Identified networking issue (NAT vs Bridged)
- Researched terminal options
- Planned Claude integration approach
- Created session tracking documentation

**Key Learnings:**
- Hyper-V External Switch required for bridged networking
- VM needs proper resources for containerized services

**Next Session Goal:**
Install Docker and Docker Compose, set up /opt/homeserver structure, deploy first test container.

---

### Session 2 - 2024-11-21
**Duration:** ~3 hours
**Focus:** Development environment setup, quality of life tools, Docker installation

**Accomplishments:**
- Installed and configured ZSH with Oh My Zsh
- Set up productivity tools (bat, exa, fzf, lazygit, btop, etc.)
- Fixed `exa --git` error (Ubuntu package limitation)
- Fixed `bat` command (Ubuntu names it `batcat`)
- Installed Docker Engine and Docker Compose V2
- Configured user permissions for Docker
- Installed and tested lazydocker
- Created comprehensive documentation:
  - `QOL_TOOLS_GUIDE.md` (tool usage reference)
  - `ZSH_SETUP_SOLUTION.md` (ZSH troubleshooting)
  - `DOCKER_INSTALLATION_GUIDE.md` (Docker setup guide)
  - `DOCKER_QUICK_COMMANDS.md` (command reference)
  - `setup-quality-of-life.sh` (automated installation)

**Key Learnings:**
1. **VS Code Remote SSH persistent connections**: Simply typing `exit` in VS Code terminal doesn't create a new session. Group changes require either:
   - Killing VS Code server process
   - Using Windows Terminal for logout/login
   - Using `newgrp docker` as temporary workaround

2. **ZSH default shell in VS Code**: System default shell (via `chsh`) doesn't affect VS Code - need `.vscode/settings.json` to configure terminal profile

3. **Ubuntu package naming**: Some packages have different names on Ubuntu:
   - `bat` → `batcat` (requires symlink)
   - `exa` package lacks git support (use without `--git` flag)

**Current Status:**
✅ Foundation phase complete - ready for service deployment!

**Next Session Goal:**
Deploy first services (Caddy reverse proxy or initial application)

---

## Checklist for Foundation Phase

**Foundation Setup:**
- [x] VM created with correct specs (6 cores, 16GB RAM, 200GB disk)
- [x] Ubuntu Server 22.04 LTS installed
- [x] SSH enabled and working
- [x] Bridged networking configured ✅
- [x] VM IP assigned: 192.168.1.200 ✅
- [x] System packages updated
- [x] ZSH + Oh My Zsh installed and configured
- [x] Quality of life tools installed (bat, exa, fzf, lazygit, btop, etc.)
- [x] VS Code Remote SSH configured
- [x] Docker Engine installed
- [x] Docker Compose V2 installed
- [x] User added to docker group
- [x] lazydocker installed
- [x] Docker tested successfully
- [x] Project directory structure created (/opt/homeserver)
- [x] Git repository initialized
- [x] Comprehensive documentation created

**Optional:**
- [ ] IP reserved in router DHCP (can do later)
- [ ] SSH key authentication (currently using password)

**✅ Foundation Phase: 100% Complete**

Ready for service deployment!

---

### Session 3 - 2025-11-22
**Duration:** ~4 hours
**Focus:** Public website deployment, SSL/TLS configuration, Caddy modular setup

**Accomplishments:**
- ✅ Deployed first public-facing website (Hello World)
- ✅ Configured Cloudflare Tunnel (4 active connections to Madrid datacenters)
- ✅ Set up Cloudflare DNS (CNAME records for domain routing)
- ✅ Generated and configured Cloudflare Origin Certificates (15-year validity)
- ✅ Configured Caddy reverse proxy with Full SSL mode
- ✅ Fixed critical SSL/TLS handshake issues:
  - Problem: Bare domain names in Caddyfile caused auto-HTTPS conflicts
  - Solution: Explicitly use `https://` prefix for site blocks
  - Problem: SNI (Server Name Indication) mismatch in TLS handshake
  - Solution: Added `originServerName` to cloudflared config
- ✅ Restructured Caddy configuration to modular architecture:
  - Master Caddyfile with global options and reusable snippets
  - Individual service configs in `sites/` directory
  - Template file for easy service addition
- ✅ Created comprehensive documentation:
  - `/opt/homeserver/.claude/docs/adding-services.md` (complete guide)
  - `/opt/homeserver/services/caddy/README.md` (quick reference)
  - `/opt/homeserver/services/caddy/sites/_template.caddy` (service template)

**Architecture Deployed:**
```
User (HTTPS) → Cloudflare Edge → Encrypted Tunnel → Caddy (HTTPS with Origin Certs) → hello-world (HTTP)
```

**Key Configuration Files:**
1. `/opt/homeserver/docker-compose.yml` - 3 services: caddy, hello-world, cloudflared
2. `/opt/homeserver/services/caddy/Caddyfile` - Master config with global options
3. `/opt/homeserver/services/caddy/sites/hello-world.caddy` - Service-specific config
4. `/opt/homeserver/services/cloudflared/config.yml` - Tunnel ingress rules with SNI
5. `/opt/homeserver/services/caddy/certs/` - Origin certificates (valid until 2040)

**Key Learnings:**

1. **Caddy Protocol Specification:**
   - Without `http://` or `https://` prefix, Caddy tries to be "helpful" and enables HTTPS
   - Explicit `https://` prefix + `auto_https off` gives full control
   - This prevents redirect loops and port conflicts

2. **SNI (Server Name Indication) in TLS:**
   - Cloudflare Origin Certificates are issued for specific hostnames
   - When cloudflared connects to `https://caddy:443`, it needs to send the correct hostname in TLS SNI
   - Solution: `originServerName: mykyta-ryasny.dev` in cloudflared config
   - Without this, TLS handshake fails with "internal error"

3. **Cloudflare SSL Modes:**
   - **Flexible**: HTTPS (user→Cloudflare), HTTP (Cloudflare→server) - Less secure
   - **Full**: HTTPS end-to-end, accepts self-signed certs - Better security
   - **Full (strict)**: HTTPS with publicly-trusted certs only - Most secure
   - Using **Full** mode with Cloudflare Origin Certificates

4. **Modular Caddy Configuration:**
   - One master Caddyfile with `import sites/*.caddy`
   - Each service gets its own `.caddy` file
   - Reusable snippets eliminate code duplication
   - Scales infinitely without cluttering one file
   - Git-friendly (clear diffs for service changes)

5. **Docker Volume Mounts:**
   - Adding new volume mounts to docker-compose.yml requires container recreation
   - `docker compose restart` doesn't pick up volume changes
   - Must use `docker compose up -d` to recreate with new mounts

**Domain & Infrastructure:**
- Domain: mykyta-ryasny.dev (purchased and configured)
- Cloudflare Tunnel ID: `07fbc124-6f0e-40c5-b254-3a1bdd98cf3c`
- SSL Mode: Full (end-to-end encryption with Origin Certificates)
- Tunnel Status: 4 active QUIC connections (mad01, mad05, mad06 datacenters)
- Public Site: https://mykyta-ryasny.dev ✅ LIVE

**Debugging Journey:**
1. Initial issue: Site showing 502 Bad Gateway
2. Found: Caddy auto-HTTPS was causing HTTP→HTTPS redirects
3. Fixed: Added `auto_https off` globally
4. New issue: Still not working - Caddy trying to use port 443 anyway
5. Fixed: Added `http://` prefix to site addresses
6. Site worked temporarily, then broke again
7. Found: TLS handshake failing between cloudflared and Caddy
8. Diagnosis: SNI hostname mismatch (using "caddy" instead of domain)
9. Final fix: Added `originServerName` to cloudflared config
10. Result: Full SSL working perfectly! 🎉

**Current Status:**
✅ Public website live with Full SSL encryption
✅ Modular Caddy configuration ready for scaling
✅ Infrastructure as Code (all configs version-controlled)
✅ Comprehensive documentation for adding services
✅ Zero exposed ports (everything through Cloudflare Tunnel)

**Next Session Goals:**
- Deploy additional services (Plex, qBittorrent, etc.) using the modular template
- Or: Deploy portfolio website to replace Hello World
- Or: Set up monitoring and logging (Grafana, Prometheus)
- Or: Implement automated backups

**Tailscale VPN Status:**
- ✅ Configured and working
- Access server via: `mykyta@home-server` (Tailscale Magic DNS)
- IP: Dynamic (Tailscale assigns from 100.x.x.x range)
- Purpose: Secure SSH access from anywhere

---

### Session 4 - 2025-11-22
**Duration:** ~1.5 hours
**Focus:** Documentation reorganization and quality of life tools encouragement

**Accomplishments:**
- ✅ Created organized documentation structure with clear separation of concerns
- ✅ Created three main folders: `docs/` (user guides), `sessions/` (session notes), `.claude/` (architecture)
- ✅ Moved user-facing guides from `.claude/` to `docs/`:
  - `migration_guide.md` → `docs/migration-guide.md`
  - `.claude/docs/adding-services.md` → `docs/adding-services.md`
  - `QUICK_REFERENCE.md` → `docs/QUICK_REFERENCE.md`
- ✅ Removed confusing `.claude/docs/` folder
- ✅ Created comprehensive README files for each documentation folder
- ✅ Updated all documentation references and links in:
  - `CLAUDE.md` - Updated with proper file locations
  - Root `README.md` - Fixed broken links and structure
  - `docs/README.md` - Added new service guides section
- ✅ Added "Quality of Life Tools Usage" section to CLAUDE.md
  - Encourages use of `ll`, `bat`, `lazydocker`, `lazygit`, `btop`
  - Ensures both user and Claude build good habits with installed tools

**Key Learnings:**

1. **Documentation Organization:**
   - Clear separation prevents confusion about who docs are for
   - `docs/` = user self-service guides
   - `sessions/` = project progress tracking (for Claude context)
   - `.claude/` = architecture and technical specs (for Claude reference)
   - This structure scales well as project grows

2. **Tool Usage Encouragement:**
   - Installing tools isn't enough - need to build habits
   - Adding explicit reminders in CLAUDE.md ensures consistent usage
   - Visual tools (lazydocker, lazygit) are more intuitive than raw commands
   - Enhanced commands (ll, bat) make daily work more pleasant

3. **Documentation Maintenance:**
   - Files can end up in wrong places as project evolves
   - Regular cleanup prevents confusion later
   - README files in each folder clarify purpose and usage
   - Updated references ensure everything stays connected

**Current Status:**
✅ Clean, well-organized documentation structure
✅ All user guides consolidated in `docs/` folder
✅ Clear navigation with README files everywhere
✅ Quality of life tools actively encouraged
✅ Production infrastructure still running perfectly (caddy, cloudflared, hello-world)

---

### Session 4 - 2025-11-22
**Duration:** ~2 hours
**Focus:** Media automation stack deployment (Jellyfin + Arr Stack)

**Accomplishments:**
- ✅ Refactored monolithic docker-compose.yml into modular files using `include:` directive
  - `compose/proxy.yml` - Caddy reverse proxy
  - `compose/tunnel.yml` - Cloudflare Tunnel
  - `compose/web.yml` - Static websites
  - `compose/media.yml` - Media automation services
- ✅ Reorganized services directory by function (proxy/, tunnel/, web/, media/)
- ✅ Deployed complete media stack:
  - Jellyfin (streaming.mykyta-ryasny.dev)
  - qBittorrent (torrent.mykyta-ryasny.dev)
  - Radarr (movies.mykyta-ryasny.dev)
  - Sonarr (tv.mykyta-ryasny.dev)
  - Prowlarr (indexers.mykyta-ryasny.dev)
  - Jellyseerr (requests.mykyta-ryasny.dev)
- ✅ Configured basic auth for admin services
- ✅ Updated all services to Europe/Madrid timezone
- ✅ Added all 6 media subdomains to Cloudflare Tunnel config
- ✅ Created comprehensive documentation in SESSION_3_MEDIA_STACK.md
- ✅ Updated adding-services.md with critical requirements

**Key Learnings:**
1. **🔴 CRITICAL: Cloudflare DNS Proxy Status**
   - DNS records MUST be "Proxied" (orange cloud), NOT "DNS only" (grey cloud)
   - This was the root cause of 1+ hour troubleshooting
   - "DNS only" bypasses Cloudflare's routing, preventing tunnel from working

2. **Caddyfile Format Requirements**
   - ALWAYS use `https://` prefix in site blocks
   - Renamed `.caddy` → `.Caddyfile` for syntax highlighting

3. **Container Startup Order**
   - Cloudflared may try to connect before Caddy is ready (temporary connection refused errors)
   - Auto-reconnects make this self-healing

**Current Status:**
✅ All 6 media services deployed and accessible via HTTPS
✅ Infrastructure refactored into clean modular structure
✅ Comprehensive troubleshooting knowledge documented

**Next Session Goals:**
- Configure Prowlarr with torrent indexers
- Connect Radarr/Sonarr to Prowlarr and qBittorrent
- Configure Jellyfin library paths
- Connect Jellyseerr to Jellyfin, Radarr, and Sonarr
- Set up Telegram bots and notifications
- Test complete automation workflow

---

### Session 5 - 2025-11-22
**Duration:** ~3 hours
**Focus:** Monitoring stack deployment - Grafana Loki centralized logging

**Accomplishments:**
- ✅ Deployed production-grade centralized logging system (Grafana Loki stack)
- ✅ Upgraded entire stack to Loki 3.0.0 and Promtail 3.0.0
- ✅ Fixed critical Docker API version mismatch (Promtail 2.9.3 couldn't communicate with Docker daemon)
- ✅ Migrated Loki configuration from deprecated boltdb-shipper (v11) to modern TSDB (v13 schema)
- ✅ Successfully collecting logs from all 12 Docker containers in real-time
- ✅ Deployed Grafana 10.2.2 with provisioned datasource configuration
- ✅ Made monitoring accessible at https://monitor.mykyta-ryasny.dev
- ✅ Created comprehensive documentation:
  - `docs/MONITORING_SETUP_GUIDE.md` - 60+ page deep dive on Loki architecture, LogQL, and observability
  - `docs/LOGQL_QUICK_REFERENCE.md` - LogQL query syntax and common patterns
  - `docs/DOCKER_RECOVERY.md` - Recovery procedures after `docker compose down`
- ✅ Updated .gitignore with security audit and proper path exclusions

**Technical Details:**
- **Stack Components:**
  - Loki 3.0.0: Log aggregation with TSDB index storage
  - Promtail 3.0.0: Docker service discovery and log shipping
  - Grafana 10.2.2: Visualization and querying interface

- **Logs Being Collected From:**
  - Media: jellyfin, jellyseerr, prowlarr, radarr, sonarr, qbittorrent
  - Infrastructure: caddy, cloudflared, grafana, loki, promtail, hello-world

- **Configuration Files Created/Modified:**
  - `compose/monitoring.yml` - Monitoring stack service definitions
  - `services/monitoring/loki/loki-config.yml` - Loki 3.0 configuration with TSDB
  - `services/monitoring/promtail/promtail-config.yml` - Docker discovery and label extraction
  - `services/monitoring/grafana/grafana.ini` - Grafana server settings
  - `services/monitoring/grafana/provisioning/datasources/loki.yml` - Auto-configured datasource
  - `services/proxy/caddy/sites/monitoring.Caddyfile` - Reverse proxy for Grafana
  - `services/tunnel/cloudflared/config.yml` - Added monitor subdomain route

**Errors Fixed During Session:**
1. **Path Resolution**: Docker Compose `include` directive changes working directory context
   - Solution: Changed `./services/` to `../services/` in compose/monitoring.yml

2. **Permission Denied**: Config files created with 0600, containers run as different users
   - Solution: `chmod 644` on all config files for world-readable access

3. **Loki Config Schema**: table_manager deprecated in Loki 2.9+, completely removed in 3.0
   - Solution: Migrated to compactor-based retention with `retention_enabled: true`

4. **Grafana Alerting Conflict**: Legacy and unified alerting both enabled
   - Solution: Disabled legacy alerting, kept unified alerting

5. **Caddy 502 Bad Gateway**: Caddy only on `web` network, Grafana on `proxy` network
   - Solution: Added Caddy to both networks in compose/proxy.yml

6. **Missing Datasource UID**: Dashboard referenced datasource `loki` but no UID specified
   - Solution: Added `uid: loki` to datasources/loki.yml

7. **Missing Home Dashboard**: grafana.ini referenced non-existent home.json
   - Solution: Commented out `default_home_dashboard_path`

8. **LogQL Query Too Broad**: Empty-compatible matchers not allowed for performance
   - Solution: Documented proper query patterns in LogQL reference

9. **Promtail Docker API Mismatch**: Client version 1.42 too old for Docker API 1.44+
   - Solution: Upgraded Promtail 2.9.3 → 3.0.0 with compatible Docker client

**Key Learnings:**

1. **Docker API Compatibility:**
   - Container images must match host Docker daemon API version
   - Older images may have outdated Docker clients that can't communicate with newer daemons
   - Error: "client version 1.42 is too old. Minimum supported API version is 1.44"
   - Solution: Upgrade to newer image versions

2. **Loki 3.0 Migration:**
   - TSDB replaced boltdb-shipper for better performance and scalability
   - Schema v13 is the current standard (v11 deprecated)
   - Many config fields moved/renamed between major versions
   - New `common` section consolidates shared configuration
   - `query_timeout` moved from querier config
   - Always consult migration guides for major version upgrades

3. **Infrastructure as Code Benefits:**
   - All monitoring configured via version-controlled files
   - Grafana datasources provisioned automatically (no manual UI setup)
   - Can recreate entire stack from config files
   - Makes debugging easier (compare configs vs running state)

4. **Observability Foundation:**
   - Centralized logging is critical for debugging distributed systems
   - LogQL provides powerful filtering without expensive full-text indexing
   - Labels enable efficient querying and aggregation
   - Proper monitoring makes troubleshooting dramatically faster
   - 30-day retention provides good balance of storage vs history

5. **Label Extraction from Docker:**
   - Promtail auto-discovers containers via Docker socket
   - Docker metadata (container name, compose service, labels) becomes Loki labels
   - Cardinality matters: too many unique labels degrades performance
   - Custom labels via `com.homeserver.*` provide service grouping

**Current Infrastructure Status:**
```
✅ 12 containers running and monitored:
   - Reverse Proxy: Caddy
   - Tunnel: Cloudflare Tunnel
   - Monitoring: Loki 3.0.0, Promtail 3.0.0, Grafana 10.2.2
   - Media: Jellyfin, Jellyseerr, Prowlarr, Radarr, Sonarr, qBittorrent
   - Web: hello-world demo

✅ All services accessible via HTTPS through Cloudflare Tunnel
✅ All logs centralized in Loki (queryable via Grafana)
✅ 30-day log retention configured
✅ Infrastructure as Code (all configs version-controlled)
```

**Access Points:**
- 📊 Grafana Monitoring: https://monitor.mykyta-ryasny.dev (admin/admin)
- 📺 Jellyfin: https://streaming.mykyta-ryasny.dev
- 🎬 Jellyseerr: https://requests.mykyta-ryasny.dev
- 🔍 Prowlarr: https://indexers.mykyta-ryasny.dev
- ⬇️ qBittorrent: https://torrent.mykyta-ryasny.dev
- 🎥 Radarr: https://movies.mykyta-ryasny.dev
- 📺 Sonarr: https://tv.mykyta-ryasny.dev

**Example LogQL Queries to Try:**
```logql
# View all logs from Jellyfin
{container="jellyfin"}

# See all media service logs
{service_group="media"}

# Find errors across all containers
{level="error"}

# View Caddy proxy logs
{container="caddy"}

# Monitor qBittorrent downloads
{container="qbittorrent"}

# Count errors per minute
count_over_time({level="error"}[1m])

# Top 5 noisiest containers
topk(5, sum by (container) (count_over_time({container!=""}[1h])))
```

**Planning Started (for Next Session):**
- 🔐 **SSO Authentication System**: Designed architecture for Authelia + PostgreSQL + Redis
  - Planned PostgreSQL backend for user storage (learning opportunity)
  - Designed custom Angular dashboard (learning Angular)
  - Researched forward authentication pattern
  - Will eliminate subdomain sprawl with single sign-on

**Next Session Goals (Priority: Authentication System):**
- 🔑 **Deploy Authentication Infrastructure**:
  - Complete Authelia configuration with PostgreSQL
  - Set up Redis for session caching
  - Create initial admin user
  - Configure Caddy for forward authentication
  - Add auth.mykyta-ryasny.dev and home.mykyta-ryasny.dev subdomains

- 🅰️ **Start Angular Dashboard** (Learning Project):
  - Generate Angular project structure
  - Set up authentication service
  - Build login page component
  - Create service card components
  - Learn Angular Material

- 🔒 **Protect Existing Services**:
  - Update all Caddyfiles to use Authelia forward auth
  - Test SSO flow across services
  - Configure per-service access control rules

**Other Goals (Lower Priority):**
- 🔐 Change default Grafana password from admin/admin
- 📊 Create custom Grafana dashboards for specific services
- 🔔 Set up alerting rules (e.g., notify on error spikes)
- 📈 Consider adding Prometheus for metrics (complement logs with metrics)
- 💾 Configure backup strategy for Grafana dashboards and Loki data

**Git Status:**
- ✅ .gitignore updated to exclude Loki data and Promtail positions
- ✅ Ready to commit: Monitoring stack configuration
- ⚠️  Note: Some Grafana/Loki data directories have restricted permissions (expected, git will ignore)
- 📝 Prepared for auth system: Directory structure created, compose/auth.yml started

---

### Session 6 - 2025-11-22 (Continued)
**Duration:** Extended session
**Focus:** Authentication System Deployment - Authelia SSO with PostgreSQL and Redis

**Accomplishments:**
- ✅ Deployed complete authentication stack (PostgreSQL 16, Redis 7, Authelia)
- ✅ Created and configured Authelia with proper environment variables
- ✅ Set up file-based authentication with secure Argon2id password hashing
- ✅ Configured Caddy reverse proxy for [auth.Caddyfile](../services/proxy/caddy/sites/auth.Caddyfile)
- ✅ Added auth subdomain to Cloudflare Tunnel configuration
- ✅ All containers healthy and communicating properly
- ✅ Database schema successfully migrated (0 → 23)

**Technical Details:**

**Containers Deployed:**
1. **postgres-auth** - PostgreSQL 16-alpine with health checks
2. **redis-auth** - Redis 7-alpine with persistence (AOF)
3. **authelia** - Latest Authelia with forward auth capabilities

**Key Files Created:**
- [compose/auth.yml](../compose/auth.yml) - Authentication stack orchestration
- [services/auth/authelia/configuration.yml](../services/auth/authelia/configuration.yml) - Authelia main config
- [services/auth/authelia/users_database.yml](../services/auth/authelia/users_database.yml) - Admin user definition
- [services/proxy/caddy/sites/auth.Caddyfile](../services/proxy/caddy/sites/auth.Caddyfile) - Reverse proxy config
- `.env` - Environment variables (copied from .env.auth)

**Errors Encountered and Fixed:**

1. **PostgreSQL Password Not Found**
   - Cause: Wrong env_file path (`../.env.auth` went to wrong directory)
   - Fix: Corrected path understanding and environment variable loading

2. **Docker Compose Include Context Issue**
   - Cause: Include directive changes working directory to included file's location
   - Fix: Removed env_file directives, used main .env instead

3. **Top-level env_file Not Allowed**
   - Cause: Newer Docker Compose format restriction
   - Fix: Copied `.env.auth` to `.env` (auto-loaded by Docker Compose)

4. **Authelia Configuration Schema Errors**
   - Cause: Breaking changes in Authelia 4.39.14
   - Fixes: Changed to `address` format, removed `asset_path`, removed nested `password_policy`

5. **Environment Variable Substitution**
   - Cause: Authelia YAML doesn't auto-substitute `${VAR}` syntax
   - Fix: Relied on AUTHELIA_* prefixed environment variables instead

6. **Wrong Environment Variable Name**
   - Cause: Used `AUTHELIA_STORAGE_PASSWORD` instead of `AUTHELIA_STORAGE_POSTGRES_PASSWORD`
   - Fix: Corrected to proper naming pattern: `AUTHELIA_<CONFIG_SECTION>_<SUBSECTION>_<PARAMETER>`
   - Result: ✅ Database authentication successful, schema migration completed

**Key Learnings:**

- **Docker Compose Environment Loading**: Automatically loads `.env` from project root
- **Authelia Environment Variables**: Strict naming pattern must be followed exactly
- **Caddyfile Pattern**: All sites should use `import cf_tls` snippet for consistency
- **Docker Compose Include**: Changes path resolution context to included file's directory

**Current Infrastructure Status:**

**Total Containers Running:** 15
- 3x Authentication (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy)
- 1x Tunnel (cloudflared)
- 1x Web (nginx)
- 6x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr)
- 3x Monitoring (loki, promtail, grafana)

**Networks:**
- `proxy` - Caddy and all services needing external access
- `media` - Media stack internal communication
- `monitoring` - Loki + Promtail + Grafana
- `auth` - PostgreSQL + Redis + Authelia internal communication
- `web` - Legacy web network

**Access Points:**
- https://mykyta-ryasny.dev - Main website
- https://www.mykyta-ryasny.dev - WWW redirect
- https://torrent.mykyta-ryasny.dev - qBittorrent
- https://streaming.mykyta-ryasny.dev - Jellyfin
- https://movies.mykyta-ryasny.dev - Radarr
- https://tv.mykyta-ryasny.dev - Sonarr
- https://indexers.mykyta-ryasny.dev - Prowlarr
- https://requests.mykyta-ryasny.dev - Jellyseerr
- https://monitor.mykyta-ryasny.dev - Grafana
- https://auth.mykyta-ryasny.dev - Authelia (⚠️ DNS cache issue - see below)

**Known Issues:**

1. **DNS Cache Blocking Browser Access**
   - **Issue**: auth.mykyta-ryasny.dev returns ERR_NAME_NOT_RESOLVED in browser
   - **Root Cause**: Local computer DNS cache has stale negative entry
   - **Verification Done**:
     - ✅ DNS resolves correctly via Google DNS (8.8.8.8)
     - ✅ Cloudflare DNS records correct and proxied
     - ✅ Caddy serving the domain correctly
     - ✅ Cloudflare Tunnel routing configured
     - ✅ Authelia health endpoint responding internally
   - **Resolution Needed**: Flush DNS cache on local computer and restart browser
   - **Commands** (for next session):
     - Windows: `ipconfig /flushdns`
     - Mac: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
     - Linux: `sudo systemd-resolve --flush-caches`

**Next Session Goals:**

1. **Resolve DNS Cache Issue**
   - Flush local computer DNS cache
   - Restart browser completely
   - Verify access to https://auth.mykyta-ryasny.dev

2. **Test Authelia Login**
   - Access auth portal
   - Login with admin credentials
   - Verify 2FA setup flow
   - Confirm session management works

3. **Configure Forward Authentication**
   - Pick test service (suggested: Grafana at monitor.mykyta-ryasny.dev)
   - Add forward_auth directive to service's Caddyfile
   - Configure forward_auth snippet in main Caddyfile

4. **Test Complete SSO Flow**
   - Access protected service (e.g., Grafana)
   - Get redirected to Authelia
   - Login successfully
   - Verify redirect back to original service
   - Test session persistence across services

5. **Protect Additional Services**
   - Roll out forward auth to media services
   - Configure access control rules per service
   - Test different policy levels (bypass, one_factor, two_factor)

**Authentication Architecture:**

```
Internet → Cloudflare Tunnel → Caddy (reverse proxy)
                                   ↓
                    Protected Service (e.g., Grafana)
                                   ↓
                    Forward Auth → Authelia:9091
                                   ↓
                              PostgreSQL (users/config)
                              Redis (sessions)
```

**Access Control Policies Configured:**
- `auth.mykyta-ryasny.dev` - **bypass** (prevents redirect loop)
- `monitor.mykyta-ryasny.dev` - **two_factor** (admins only)
- `indexers.mykyta-ryasny.dev` - **two_factor** (admins only)
- `torrent.mykyta-ryasny.dev` - **two_factor** (admins only)

**Git Status:**
- ✅ Ready to commit: Authentication stack deployment
- ✅ New files: compose/auth.yml, Authelia configs, auth Caddyfile
- ✅ Modified: docker-compose.yml, cloudflared config.yml
- ⚠️ Note: .env file contains secrets (should be in .gitignore)

---

### Session 6 (Continued) - 2025-11-22 - Final Update
**Additional Progress After DNS Resolution:**

**Final Accomplishments:**
- ✅ **Successfully accessed Authelia login portal** at https://auth.mykyta-ryasny.dev
- ✅ **Password reset completed** - Generated new Argon2id hash and updated users_database.yml
- ✅ **Verified authentication working** - Admin user login successful
- ✅ **DNS propagation confirmed** - All subdomains resolving correctly globally

**Troubleshooting Resolved:**
1. **Password Hash Issue**
   - Problem: User couldn't remember password for initial hash
   - Solution: Generated fresh password hash using Docker command
   - Command: `docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'password'`
   - Updated hash in users_database.yml
   - Restarted Authelia container to pick up new password

2. **DNS Cache Resolution**
   - Problem: Local DNS cache prevented browser from resolving auth.mykyta-ryasny.dev
   - Verification: DNS resolving correctly via public DNS servers (8.8.8.8)
   - Solution: User flushed local DNS cache and restarted browser
   - Result: ✅ Authelia login page now accessible

**Session Complete Status:**

✅ **Authentication Infrastructure - FULLY OPERATIONAL**
- PostgreSQL database healthy
- Redis session store healthy
- Authelia authentication server healthy
- Caddy reverse proxy configured and serving
- Cloudflare Tunnel routing traffic correctly
- DNS propagated globally
- **Admin user can successfully log in**

**What's Working:**
- https://auth.mykyta-ryasny.dev → Authelia login portal (VERIFIED)
- Backend authentication flow functional
- Session storage via Redis operational
- User database file-based authentication working

**Ready for Next Session:**
The authentication foundation is now complete and tested. Next session can proceed with:
1. Configure forward authentication for protected services
2. Add forward_auth directive to Grafana (test service)
3. Test complete SSO flow end-to-end
4. Roll out authentication to media services
5. Configure different access policies (one_factor vs two_factor)

**Key Learning:**
- Argon2id password hashing is one-way - hashes cannot be reversed
- Always document passwords in secure password manager
- Docker container restarts required when read-only volume files change
- DNS caching can delay access even when server-side configuration is perfect

---

### Session 7 - 2025-11-23
**Duration:** ~3 hours
**Focus:** SSO rollout, complete media automation setup, Docker volume optimization

**Accomplishments:**
- ✅ **Rolled out SSO authentication to all services**
  - Implemented Authelia forward authentication across all media services
  - Created reusable `authelia_auth` snippet in Caddyfile
  - Protected: Grafana, qBittorrent, Radarr, Sonarr, Prowlarr, Jellyseerr, Jellyfin
  - Configured Grafana auth.proxy to trust Authelia headers
  - Fixed logout redirect to clear SSO sessions properly

- ✅ **Complete media automation stack configured and tested**
  - Added working torrent indexers: YTS, EZTV, TorrentGalaxy, Nyaa
  - Connected Prowlarr to Radarr and Sonarr
  - Connected Radarr and Sonarr to qBittorrent
  - Created Jellyfin libraries for Movies and TV
  - Connected Jellyseerr to Jellyfin, Radarr, and Sonarr
  - **Successfully tested end-to-end workflow**: Request → Download → Import → Stream

- ✅ **Fixed critical Docker volume configuration issue**
  - **Problem**: Radarr was COPYING files instead of MOVING them (wasted 86GB with Wicked movie)
  - **Root Cause**: Separate volume mounts prevented hardlinks between `/downloads` and `/movies`
  - **Solution**: Unified all media services to single `/data/media` parent mount
  - **Result**: Files now MOVE instantly using hardlinks (no space waste, instant import)

- ✅ **Updated all service configurations for new volume structure**
  - Moved downloads folder from `services/media/qbittorrent/downloads/` to `data/media/downloads/`
  - Updated qBittorrent config paths to `/data/media/downloads/`
  - Updated Radarr root folder from `/movies` to `/data/media/movies`
  - Updated Sonarr root folder from `/tv` to `/data/media/tv`
  - Updated Jellyseerr default paths for both services
  - Added `networks: web: external: true` to media.yml

**Technical Changes:**

**Files Modified:**
1. `/opt/homeserver/compose/media.yml` - Changed all services to use unified `/data/media` mount
2. `/opt/homeserver/services/media/qbittorrent/config/qBittorrent/qBittorrent.conf` - Updated paths
3. `/opt/homeserver/services/proxy/caddy/Caddyfile` - Added `authelia_auth` snippet
4. `/opt/homeserver/services/proxy/caddy/sites/media.Caddyfile` - Replaced basicauth with SSO
5. `/opt/homeserver/services/proxy/caddy/sites/monitoring.Caddyfile` - Added SSO
6. `/opt/homeserver/services/monitoring/grafana/grafana.ini` - Added auth.proxy and logout redirect
7. `/opt/homeserver/services/auth/authelia/users_database.yml` - Updated email to MykytaRyasny@gmail.com
8. `/opt/homeserver/services/auth/authelia/configuration.yml` - Changed policies from two_factor to one_factor

**Errors Fixed:**

1. **Two-Factor Authentication Required**
   - Issue: Grafana asking for 2FA setup with wrong email
   - Fix: Updated email in users_database.yml and changed policy to one_factor

2. **Grafana Logout Not Clearing SSO Session**
   - Issue: Logout only cleared Grafana session, not Authelia
   - Fix: Added `signout_redirect_url = https://auth.mykyta-ryasny.dev/logout`

3. **Media Services Blocked by Access Policy**
   - Issue: Services requiring two_factor but user logged in with one_factor
   - Fix: Changed all service policies to one_factor and commented out wildcard rule

4. **qBittorrent Configuration Getting Overwritten**
   - Issue: Config changes lost after container restart
   - Fix: Stop container → edit config → start container

5. **1337x Torrent Indexer Connectivity Issues**
   - Issue: Connection refused to 1337x.to
   - Fix: Switched to more reliable indexers (YTS, EZTV, TorrentGalaxy, Nyaa)

6. **Sonarr /tv Folder Permission Error**
   - Issue: "Folder '/tv/' is not writable by user 'abc'"
   - Fix: Restarted Sonarr container to detect newly created folder

7. **Files Being Copied Instead of Moved (CRITICAL)**
   - Issue: 86GB movie file duplicated (172GB total), ran out of disk space
   - Root Cause: Separate Docker volume mounts prevented hardlinks
   - Fix: Unified all services to single `/data/media` parent mount
   - Result: Files now move instantly using hardlinks

**Key Learnings:**

1. **Docker Volume Hardlinks**
   - Hardlinks only work within the same filesystem/volume mount
   - Separate mounts (`/downloads` and `/movies`) force copy operations
   - Solution: Use single parent mount (`/data/media`) containing all subdirectories
   - Benefits: Instant file moves, no disk space duplication, faster imports

2. **Authelia Forward Authentication Pattern**
   - Caddy forwards request to Authelia's `/api/verify` endpoint
   - Authelia checks session validity and returns headers
   - Headers include: Remote-User, Remote-Groups, Remote-Name, Remote-Email
   - Backend services trust these headers from reverse proxy

3. **Grafana Auth Proxy Configuration**
   - Grafana can delegate authentication to reverse proxy
   - Must configure `[auth.proxy]` section to trust headers
   - Logout requires redirect to SSO logout endpoint to clear session

4. **Access Control Policy Conflicts**
   - Specific rules take precedence over wildcard rules
   - Wildcard `*.domain.com` rules can block services unintentionally
   - Best practice: Define explicit rules per service/group

5. **Radarr/Sonarr Import Workflow**
   - Downloads complete in `/downloads/`
   - Radarr/Sonarr detect completion (~1 minute polling)
   - Files renamed and moved to `/movies/` or `/tv/`
   - With hardlinks: Move is instant, torrent keeps seeding
   - Without hardlinks: Files copied (slow, wastes space)

**Architecture Now:**

```
Internet → Cloudflare Tunnel → Caddy (with Authelia SSO)
                                   ↓
                    ┌──────────────┴──────────────┐
                    │                              │
              Media Services              Monitoring/Auth
         (Jellyfin, Radarr, etc.)      (Grafana, Authelia)
                    │
          /data/media (unified volume)
              ├── downloads/
              ├── movies/
              └── tv/
```

**Current Infrastructure Status:**

**Total Containers:** 15
- 3x Auth (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy)
- 1x Tunnel (cloudflared)
- 1x Web (nginx)
- 6x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr)
- 3x Monitoring (loki, promtail, grafana)

**Working Features:**
- ✅ SSO authentication protecting all services
- ✅ Complete media request workflow (Jellyseerr → Radarr/Sonarr → qBittorrent → Jellyfin)
- ✅ Efficient file handling with hardlinks (no space waste)
- ✅ Centralized logging via Grafana Loki
- ✅ Zero exposed ports (all through Cloudflare Tunnel)

**Test Workflow Confirmed Working:**
1. Request content in Jellyseerr ✅
2. Radarr/Sonarr search indexers via Prowlarr ✅
3. Send torrent to qBittorrent ✅
4. Download completes ✅
5. Radarr/Sonarr move file to library (using hardlinks) ✅
6. Jellyfin detects and streams content ✅

**Next Session Goals:**
- Configure quality profiles in Radarr (set max file sizes)
- Test complete request-to-stream workflow with new content
- Optional: Add more indexers or configure language preferences
- Optional: Set up automated library scanning in Jellyfin
- Consider implementing backup strategy for configurations

**Git Status:**
- ⚠️ Many modified files ready to commit
- Suggested commit message: "Implement SSO, complete media automation, fix Docker volumes"

---

### Session 8 - 2025-11-23 (Continued)
**Duration:** ~1 hour
**Focus:** Hardlink verification, Angular portal infrastructure setup

**Accomplishments:**
- ✅ **Verified hardlinks working correctly**
  - Confirmed Mulan movie imported using hardlinks (link count = 2)
  - Same inode for both `/downloads/` and `/movies/` paths
  - qBittorrent continues seeding while Jellyfin streams (no duplication)
  - Learned to check hardlinks using `stat -c "%i %h" filename`

- ✅ **Set up Angular portal infrastructure**
  - Created deployment directory: `/opt/homeserver/services/web/portal/dist/`
  - Configured Caddy to serve static files from `/srv/portal`
  - Created `portal.Caddyfile` with SSO protection via Authelia
  - Added portal volume mount to Caddy container
  - Configured SPA routing (fallback to index.html)
  - Set up Authelia header forwarding (X-Auth-User, X-Auth-Groups, X-Auth-Name, X-Auth-Email)
  - Added `home.mykyta-ryasny.dev` to Cloudflare Tunnel config
  - Created placeholder index.html page

**Technical Changes:**

**Files Created:**
1. `/opt/homeserver/services/proxy/caddy/sites/portal.Caddyfile` - Portal reverse proxy config
2. `/opt/homeserver/services/web/portal/dist/index.html` - Placeholder page

**Files Modified:**
1. `/opt/homeserver/compose/proxy.yml` - Added portal volume mount to Caddy
2. `/opt/homeserver/services/tunnel/cloudflared/config.yml` - Added home.mykyta-ryasny.dev route

**Errors Fixed:**

1. **Portal Files Not Accessible**
   - Issue: Caddy couldn't see `/srv/portal/` directory
   - Root Cause: Volume mount added but container not recreated
   - Fix: Stopped and recreated Caddy container with new volume mount

2. **File Permissions Issue**
   - Issue: index.html had 600 permissions (owner-only read)
   - Root Cause: File created with restrictive permissions
   - Fix: `chmod 644` to make file world-readable

**Key Learnings:**

1. **Hardlink Verification**
   - Use `stat -c "%i %h" filename` to check inode and link count
   - Link count > 1 = hardlinked file
   - Same inode = same physical file on disk
   - Quick check: `stat -c "Links: %h" filename`

2. **Docker Volume Mounts Require Container Recreation**
   - Adding new volume mounts to docker-compose.yml requires recreating container
   - `docker restart` doesn't pick up volume changes
   - Must use `docker compose up -d` or manually recreate

3. **Caddy Static File Serving**
   - Caddy can serve static files without Nginx
   - Use `file_server` directive
   - `try_files` for SPA routing
   - Headers can be set globally or per route

4. **Deployment-Ready Infrastructure**
   - Server-side setup complete for Angular deployment
   - Files deployed to `/opt/homeserver/services/web/portal/dist/` automatically served
   - GitHub Actions can deploy via SSH + SCP
   - Authelia headers available for role-based UI rendering

**Architecture Addition:**

```
home.mykyta-ryasny.dev
    ↓
Cloudflare Tunnel → Caddy (with Authelia SSO)
    ↓
Static File Server (/srv/portal)
    ↓
Angular App (user builds locally, deploys via CI/CD)
```

**Current Infrastructure Status:**

**Total Containers:** 15
- 3x Auth (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy) - Now serving portal too
- 1x Tunnel (cloudflared)
- 1x Web (nginx - hello-world, can be removed)
- 6x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr)
- 3x Monitoring (loki, promtail, grafana)

**Working Features:**
- ✅ SSO authentication protecting all services
- ✅ Complete media request workflow (Jellyseerr → Radarr/Sonarr → qBittorrent → Jellyfin)
- ✅ Efficient file handling with hardlinks (verified working)
- ✅ Centralized logging via Grafana Loki
- ✅ Zero exposed ports (all through Cloudflare Tunnel)
- ✅ Portal deployment infrastructure ready

**Access Points:**
- https://home.mykyta-ryasny.dev - Angular Portal (placeholder page, ready for deployment)
- https://streaming.mykyta-ryasny.dev - Jellyfin
- https://requests.mykyta-ryasny.dev - Jellyseerr
- https://movies.mykyta-ryasny.dev - Radarr
- https://tv.mykyta-ryasny.dev - Sonarr
- https://indexers.mykyta-ryasny.dev - Prowlarr
- https://torrent.mykyta-ryasny.dev - qBittorrent
- https://monitor.mykyta-ryasny.dev - Grafana
- https://auth.mykyta-ryasny.dev - Authelia

**Next Session Goals:**
- Build Angular portal application locally
- Implement service cards with role-based visibility
- Set up GitHub Actions for automated deployment
- Test end-to-end deployment workflow
- Optional: Add iframes for in-portal service interaction
- Consider implementing backup strategy for configurations

**Developer Notes for Angular Portal:**

**Deployment Target:**
- Server path: `/opt/homeserver/services/web/portal/dist/`
- Ensure files have `644` permissions (readable by Caddy)
- Angular build output should go directly into this directory

**Authelia Integration:**
```typescript
// Read user info from response headers
httpClient.get('/api/user-info', { observe: 'response' }).subscribe(response => {
  const username = response.headers.get('X-Auth-User');
  const groups = response.headers.get('X-Auth-Groups'); // e.g., "admins,family"
  const email = response.headers.get('X-Auth-Email');

  // Show/hide services based on groups
  if (groups?.includes('admins')) {
    // Show admin-only services (Grafana, Prowlarr, qBittorrent)
  }
});
```

**Service Card Data Structure Suggestion:**
```typescript
interface Service {
  name: string;
  url: string;
  icon: string;
  description: string;
  requiredGroups: string[]; // ['admins'] or ['admins', 'family']
  color: string;
}
```

**Git Status:**
- ⚠️ Many modified files ready to commit
- Suggested commit messages:
  - "Fix Docker volumes for hardlinks, verify working"
  - "Set up Angular portal infrastructure with Caddy and SSO"

---

**End of Session Status Notes**

_This file should be updated at the end of each session with new progress, decisions, and blockers._