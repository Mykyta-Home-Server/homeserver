# Home Server PoC - Session Status & Notes

**Last Updated:** 2025-11-30
**Current Phase:** Portal Development & SSO Integration
**Status:** 🟢 Production Infrastructure + Angular Portal in Development

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

**Tailscale VPN Status:**
- ✅ Configured and working
- Access server via: `mykyta@home-server` (Tailscale Magic DNS)
- IP: Dynamic (Tailscale assigns from 100.x.x.x range)
- Purpose: Secure SSH access from anywhere

**Note:** Session 3 goals are outdated - infrastructure has evolved significantly since then. See SESSION_LOG.md for current project state.

---

### Session N - 2025-11-30
**Duration:** ~3 hours
**Focus:** Mermaid diagram redesign with modern v11.3.0+ syntax and comprehensive documentation guidelines

**Accomplishments:**
- ✅ Complete redesign of all 11 Mermaid diagrams across 3 documentation files
- ✅ Implemented modern Mermaid v11.3.0+ syntax with semantic shapes (`@{ shape:, label: }`)
- ✅ Fixed critical rendering issues (broken Labels diagram with invalid `tag` shape)
- ✅ Applied consistent pastel color palette across all diagrams
- ✅ Implemented compact grid layouts (2x2, 3x3) to minimize whitespace
- ✅ Created comprehensive Mermaid guidelines in CLAUDE.md v3.5
- ✅ All diagrams tested and rendering correctly in live documentation site

**Diagrams Redesigned:**

**introduction.mdx (4 diagrams):**
1. System Architecture - architecture-beta with nested subgraphs (unchanged, working)
2. Media Automation Flow - 3x3 grid layout with semantic shapes
3. Authentication Flow - Sequence diagram (proper temporal representation)
4. Docker Network Architecture - 2x2 grids for auth/media networks

**ldap.mdx (4 diagrams):**
1. LDAP Authentication Architecture - 5 subgraphs with semantic shapes
2. Directory Structure - Tree with cyl root, rect OUs, circle users, hex groups
3. LDAP Authentication Flow - Sequence diagram (converted from flowchart)
4. Access Control - 2x2 grid for Admin Only services, hex groups

**monitoring.mdx (3 diagrams):**
1. Logging Architecture - 2x2 grid for containers, compact vertical flow
2. Log Flow - Linear horizontal flow with semantic shapes
3. Labels Mapping - Side-by-side vertical stacks (fixed from broken state)

**Technical Implementation:**

**Semantic Shapes (v11.3.0+):**
- `cloud` - Cloud services (Cloudflared)
- `cyl` - Databases (PostgreSQL, Redis, Loki, Jellyfin)
- `rect` - Services/processes (default)
- `circle` - Users and actors
- `hex` - Special components (FlareSolverr, groups)
- `stadium` - Labels and tags

**Grid Layout Technique:**
```mermaid
subgraph name["`**Title**`"]
    direction TB
    row1[" "]  # Invisible spacer
    row2[" "]
    Item1 ~~~ Item2  # Side by side
    Item3 ~~~ Item4
end

style row1 fill:none,stroke:none  # Hide spacers
```

**Color Palette (9 consistent pastel colors):**
- Blue (#dbeafe/#3b82f6) - Users, containers, proxy
- Cyan (#bae6fd/#0ea5e9) - SSO, Docker Engine
- Green (#a7f3d0/#10b981) - Media, LDAP
- Orange (#fed7aa/#f97316) - Storage, monitoring
- Pink (#fce7f3/#ec4899) - Auth, visualization
- Purple (#e9d5ff/#a855f7) - Management
- Yellow (#fef3c7/#f59e0b) - Processing
- Violet (#e0e7ff/#8b5cf6) - Streaming
- Red (#fecaca/#ef4444) - Admin-only

**Multi-Target Connections:**
```mermaid
Source --> Target1 & Target2 & Target3
Caddy ==> auth & media & monitor
```

**Documentation Added to CLAUDE.md v3.5:**

**New Section: "Mermaid Diagram Guidelines (v11.3.0+)"**
- Syntax reference with semantic shapes
- Layout techniques (compact grids, invisible spacers)
- Connection patterns (multi-target with `&`)
- Complete color palette table
- Subgraph title formatting
- Diagram type selection guide
- Bad vs Good examples
- 10-point maintenance checklist

**Key Learnings:**

1. **Mermaid Syntax Evolution:**
   - Old: `A[Label]`, `A[(Database)]` - deprecated
   - New: `A@{ shape: cyl, label: "Database" }` - semantic and explicit
   - Invalid shapes like `tag` cause complete rendering failures
   - Always check Mermaid documentation for valid shapes

2. **Grid Layouts for Compact Design:**
   - Use invisible spacer nodes: `row1[" "]`
   - Hide with `style row1 fill:none,stroke:none`
   - Connect side-by-side with `~~~` (invisible edges)
   - Direction control: `TB` vertical, `LR` horizontal
   - Goal: minimize whitespace, maximize information density

3. **Consistent Styling is Critical:**
   - Define color palette once, use everywhere
   - Always add `stroke-width:2px` for consistency
   - Use Markdown bold in titles: `` "`**Title**`" ``
   - Semantic shapes make diagrams self-documenting

4. **Sequence Diagrams for Flows:**
   - Better than flowcharts for request/response patterns
   - Use `actor` for users, `participant` for services
   - `->>` for requests, `-->>` for responses
   - Number steps in messages for clarity

5. **Documentation Standards:**
   - Comprehensive guidelines prevent future inconsistencies
   - Maintenance checklist ensures quality
   - Examples (bad vs good) teach best practices
   - Version control ensures knowledge persists

**Commits:**
1. `d6c81e1` - Refine Mermaid diagrams: compact layouts and remove labels
2. `5854b62` - Fix Mermaid diagrams: broken shapes and consistent color palette
3. `f2eb22e` - Redesign diagrams: compact grid layouts with minimal whitespace
4. `ce4d1f1` - Add comprehensive Mermaid v11.3.0+ diagram guidelines to CLAUDE.md

**Current Status:**
✅ All 11 diagrams rendering correctly with modern syntax
✅ Consistent pastel color palette across all visualizations
✅ Compact grid layouts minimize whitespace
✅ Comprehensive Mermaid guidelines in CLAUDE.md for future maintenance
✅ Documentation site fully updated with visual architecture diagrams

**Next Session Goals:**
- Continue with service deployment (media stack, monitoring, etc.)
- Or: Enhance existing diagrams with more detail
- Or: Create additional diagrams for new features

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

---

### Session 9 - 2025-11-25
**Duration:** ~4 hours
**Focus:** Unified LDAP authentication implementation across all services

**Accomplishments:**
- ✅ **Deployed complete LDAP infrastructure**
  - OpenLDAP 1.5.0 (LDAP directory server)
  - phpLDAPadmin 0.9.0 (web-based LDAP management)
  - Initialized directory structure with users, groups, and organizational units
  - Accessible at https://ldap.mykyta-ryasny.dev (protected by Authelia)

- ✅ **Migrated Authelia from file-based to LDAP authentication**
  - Changed authentication backend from `users_database.yml` to LDAP
  - Configured LDAP connection with proper filters and search paths
  - Successfully tested Authelia login with LDAP credentials
  - All SSO-protected services now authenticate against LDAP

- ✅ **Configured Jellyfin LDAP plugin**
  - Installed LDAP-Auth Plugin version 22.0.0.0
  - Fixed critical configuration issues:
    - Changed `LdapUsernameAttribute` from `cn` to `uid`
    - Set `LdapSearchAttributes` to just `uid` (not comma-separated list)
    - Emptied `LdapSearchFilter` to avoid malformed queries
  - Deleted conflicting Jellyfin admin user from database
  - Successfully created new Jellyfin user linked to LDAP
  - Admin filter working (LDAP admins become Jellyfin admins)

- ✅ **Configured Jellyseerr to use Jellyfin authentication**
  - Enabled Jellyfin sign-in in Jellyseerr settings
  - Jellyseerr now authenticates via Jellyfin → LDAP chain
  - No direct LDAP connection needed

- ✅ **Removed Authelia from Jellyfin and Jellyseerr**
  - Jellyfin has its own LDAP authentication
  - Jellyseerr uses Jellyfin authentication
  - Avoids double login (Authelia + service login)
  - Better mobile app and Chromecast compatibility

- ✅ **Implemented unified logout across all services**
  - Added Caddy logout interceptors for Radarr, Sonarr, Prowlarr
  - Logout buttons now redirect to Authelia logout with return URL
  - Successfully preserves return URL after re-login
  - Users return to the exact page they were on after logout/login cycle

- ✅ **Created comprehensive documentation**
  - `docs/UNIFIED_AUTH_LDAP_GUIDE.md` - Complete tested setup guide (60+ pages)
  - Documented architecture, troubleshooting, and user management
  - Included all tested configurations and commands

**Technical Changes:**

**Files Created:**
1. `/opt/homeserver/compose/ldap.yml` - LDAP services orchestration
2. `/opt/homeserver/services/auth/ldap/init.ldif` - Directory initialization
3. `/opt/homeserver/services/proxy/caddy/sites/ldap.Caddyfile` - phpLDAPadmin proxy config
4. `/opt/homeserver/docs/UNIFIED_AUTH_LDAP_GUIDE.md` - Complete documentation

**Files Modified:**
1. `/opt/homeserver/.env` - Added LDAP credentials
2. `/opt/homeserver/.gitignore` - Added LDAP data directories
3. `/opt/homeserver/docker-compose.yml` - Added ldap.yml include
4. `/opt/homeserver/services/auth/authelia/configuration.yml` - Changed to LDAP backend
5. `/opt/homeserver/services/media/jellyfin/config/data/plugins/configurations/LDAP-Auth.xml` - LDAP plugin config
6. `/opt/homeserver/services/proxy/caddy/sites/media.Caddyfile` - Added logout interceptors with return URLs
7. `/opt/homeserver/services/tunnel/cloudflared/config.yml` - Added ldap subdomain

**Errors Fixed:**

1. **qBittorrent SSO Bypass (Multiple Attempts)**
   - Problem: qBittorrent kept showing login page after Authelia
   - Root Causes: Missing `BypassAuthenticationForWhitelist=true`, config overwrite on restart, wrong subnet
   - Fix: Stop container, edit config with both networks (172.18.0.0/16 and 172.19.0.0/16), start container

2. **Jellyfin LDAP Plugin - "Found no users matching admin"**
   - Problem: Plugin couldn't find users, authentication always failed
   - Root Causes:
     - `LdapUsernameAttribute` set to `cn` instead of `uid`
     - `LdapSearchAttributes` list caused malformed filter
     - Old Jellyfin user conflicting with LDAP user creation
   - Fixes:
     - Changed `LdapUsernameAttribute` from `cn` to `uid`
     - Set `LdapSearchAttributes` to just `uid`
     - Emptied `LdapSearchFilter`
     - Deleted old Jellyfin admin user: `sqlite3 jellyfin.db "DELETE FROM Users WHERE Username='admin';"`
     - Plugin successfully created new user linked to LDAP

3. **Git Commit Failed Due to LDAP Permissions**
   - Problem: Git couldn't read LDAP config files
   - Fix: Added LDAP directories to .gitignore

4. **Authelia Configuration Syntax Error**
   - Problem: YAML syntax error after editing
   - Root Cause: Orphaned lines from old file-based auth
   - Fix: Removed orphaned configuration lines

5. **Logout Redirect Doesn't Preserve Return URL**
   - Problem: After logout and re-login, users redirected to home page
   - Desired: Return to original page
   - Fix: Added `?rd=` parameter to logout redirects:
     - Radarr: `?rd=https://movies.mykyta-ryasny.dev`
     - Sonarr: `?rd=https://tv.mykyta-ryasny.dev`
     - Prowlarr: `?rd=https://indexers.mykyta-ryasny.dev`

**Key Learnings:**

1. **LDAP Directory Structure**
   - Base DN: `dc=mykyta-ryasny,dc=dev`
   - Users: `ou=users` containing `uid=username` entries
   - Groups: `ou=groups` containing `cn=groupname` entries
   - Group membership uses `member` attribute with full DN

2. **LDAP vs PostgreSQL**
   - LDAP: Directory service optimized for authentication and user attributes
   - PostgreSQL: Relational database for application data
   - Can't use PostgreSQL as user directory for authentication
   - Authelia uses PostgreSQL for session storage, LDAP for user credentials

3. **Jellyfin LDAP Plugin Critical Settings**
   - `LdapUsernameAttribute` MUST be `uid` (not `cn`)
   - `LdapSearchAttributes` should be just `uid` (not comma-separated)
   - `LdapSearchFilter` should be empty (plugin generates correct filter)
   - `CreateUsersFromLdap` must be true for auto-creation
   - `EnableAllFolders` must be true for user creation
   - Old users must be deleted to avoid conflicts

4. **Authentication Chain**
   - Authelia (SSO) → LDAP
   - Jellyfin → LDAP (via plugin)
   - Jellyseerr → Jellyfin → LDAP (chained)
   - All use same credentials from single LDAP directory

5. **Unified Logout Implementation**
   - Caddy intercepts `/logout` paths before proxying
   - Redirects to Authelia logout with return URL parameter
   - Authelia clears session and redirects back to service
   - User must log in again, then returns to original page
   - Pattern: `redir @logout https://auth.mykyta-ryasny.dev/logout?rd=https://[service-url] 302`

6. **Docker Container Configuration Persistence**
   - Some containers overwrite config files on restart
   - Solution: Stop container, edit config, start container
   - Never edit config while container is running

**Architecture Now:**

```
LDAP (OpenLDAP)
  ├─→ Authelia (SSO for protected services)
  │     ├─→ qBittorrent (bypassed via subnet whitelist)
  │     ├─→ Radarr, Sonarr, Prowlarr (with unified logout)
  │     ├─→ Uptime Kuma (auth disabled)
  │     └─→ Grafana (with unified logout)
  │
  ├─→ Jellyfin (direct LDAP auth via plugin)
  │
  └─→ Jellyseerr (authenticates via Jellyfin → LDAP)
```

**Current Infrastructure Status:**

**Total Containers:** 17
- 2x LDAP (openldap, phpldapadmin)
- 3x Auth (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy)
- 1x Tunnel (cloudflared)
- 1x Web (nginx - can be removed)
- 6x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr)
- 3x Monitoring (loki, promtail, grafana)

**Working Features:**
- ✅ Unified LDAP authentication across all services
- ✅ Single username/password works everywhere (`admin` / `homeserver2025`)
- ✅ Centralized user management via LDAP
- ✅ SSO for protected services
- ✅ No double login for Jellyfin and Jellyseerr
- ✅ Unified logout behavior (clears SSO session, preserves return URL)
- ✅ Complete media request workflow
- ✅ Efficient file handling with hardlinks
- ✅ Centralized logging via Grafana Loki
- ✅ Zero exposed ports (all through Cloudflare Tunnel)

**Access Points:**
- https://ldap.mykyta-ryasny.dev - phpLDAPadmin (LDAP management)
- https://auth.mykyta-ryasny.dev - Authelia (SSO login)
- https://home.mykyta-ryasny.dev - Angular Portal
- https://streaming.mykyta-ryasny.dev - Jellyfin (LDAP auth, no Authelia)
- https://requests.mykyta-ryasny.dev - Jellyseerr (Jellyfin auth, no Authelia)
- https://movies.mykyta-ryasny.dev - Radarr (SSO with unified logout)
- https://tv.mykyta-ryasny.dev - Sonarr (SSO with unified logout)
- https://indexers.mykyta-ryasny.dev - Prowlarr (SSO with unified logout)
- https://torrent.mykyta-ryasny.dev - qBittorrent (SSO bypassed)
- https://monitor.mykyta-ryasny.dev - Grafana (SSO with unified logout)

**LDAP Credentials:**
- **LDAP Admin DN:** `cn=admin,dc=mykyta-ryasny,dc=dev`
- **LDAP Admin Password:** `ZRR+BWr7vErpTSzdaiZgOZEMqNmLJCDQSfi3ptVh/3A=`
- **User Login:** `admin` / `homeserver2025`

**Test Workflows Confirmed Working:**

1. **Authelia SSO with LDAP**
   - Visit protected service → Authelia login → Enter admin/homeserver2025 → Access granted ✅

2. **Jellyfin Direct LDAP**
   - Visit Jellyfin → Jellyfin login (no Authelia) → Enter admin/homeserver2025 → Access granted ✅

3. **Jellyseerr via Jellyfin**
   - Visit Jellyseerr → Click "Sign in with Jellyfin" → Enter admin/homeserver2025 → Access granted ✅

4. **Unified Logout**
   - Access Radarr → Click logout → Redirected to Authelia logout → Session cleared ✅
   - Log in again → Redirected back to Radarr (not home page) ✅

5. **User Management**
   - Add user in phpLDAPadmin → User works in all services immediately ✅

**Next Session Goals:**
- Test adding new users via phpLDAPadmin
- Configure user groups (admins vs family) and test access policies
- Optional: Build Angular portal user management UI
- Optional: Set up automated LDAP backups
- Optional: Deploy Uptime Kuma with LDAP integration
- Consider migrating from file-based to LDAP for all authentication

**Git Status:**
- ✅ Documentation created and tested
- ⚠️ Many modified files ready to commit
- Suggested commit message: "Implement unified LDAP authentication across all services"

**Important Documentation:**
- User can add new users via: https://ldap.mykyta-ryasny.dev
- Complete setup guide: `/opt/homeserver/docs/UNIFIED_AUTH_LDAP_GUIDE.md`
- All configurations tested and verified working

---

---

### Session 10 - 2025-11-27
**Duration:** ~2 hours
**Focus:** Multi-language media requests investigation and cleanup automation

**Accomplishments:**
- ✅ **Investigated Jellyseerr duplicate request limitation**
  - Researched how Jellyseerr tracks media by TMDB ID
  - Analyzed database schema (media table with tmdbId, media_request table with profileId)
  - Attempted to remove UNIQUE constraint on tvdbId to allow duplicates
  - Confirmed limitation is in application logic, not database schema

- ✅ **Database schema modification experiment**
  - Created script to remove UNIQUE constraint from media.tvdbId
  - Successfully modified database and restarted Jellyseerr
  - Tested duplicate request functionality
  - Result: Application still blocks duplicates (JavaScript validation before DB)
  - Reverted database changes back to original schema

- ✅ **Explored per-user library solutions**
  - Discussed Netflix-style "My List" approach
  - Evaluated options: per-user Jellyfin libraries vs custom Jellyseerr fork
  - Determined this requires significant custom development
  - Decided to defer until future Jellyseerr fork/plugin development

- ✅ **Cleaned up experimental scripts**
  - Removed 6 unnecessary/experimental scripts from `/opt/homeserver/scripts/`
  - Deleted: `enable-jellyseerr-profile-duplicates.sh`, `enable-jellyseerr-profile-duplicates-v2.sh`,
    `setup-per-user-libraries.sh`, `show-radarr-profiles.py`, `sync-quality-profiles.py`, `jellyfin-cleanup.sh`
  - Kept active scripts: backup/restore, LDAP tools, cleanup automation, custom format sync

- ✅ **Documented findings**
  - Created comprehensive analysis of Jellyseerr duplicate detection
  - Explained database vs application-level constraints
  - Documented why per-user libraries aren't feasible with current stack

**Technical Details:**

**Database Investigation:**
- Jellyseerr's `media` table tracks content by `tmdbId` (indexed, no UNIQUE constraint by default)
- `media_request` table has `profileId` field (structure supports multiple profiles)
- Application-level validation prevents duplicate `tmdbId` regardless of `profileId`
- Removing database constraints doesn't bypass JavaScript validation

**Files Modified:**
1. Jellyseerr database temporarily modified and reverted
2. `/opt/homeserver/scripts/` - Cleaned up 6 experimental scripts

**Key Learnings:**

1. **Application Logic vs Database Constraints**
   - Database schema can support a feature (duplicate tmdbId with different profileId)
   - Application logic can still block it before reaching database
   - Compiled JavaScript can't be easily modified without rebuilding from source
   - Container updates would overwrite any manual code modifications

2. **Jellyseerr Architecture**
   - TypeScript source code compiled to JavaScript
   - Runs in Node.js container
   - Duplicate detection happens in API endpoint handlers
   - Would require forking repository and maintaining custom build

3. **Per-User Library Complexity**
   - Jellyfin shows all library content to users with access
   - No built-in "only show content you requested" feature
   - Would require separate Jellyfin libraries per user
   - Automated user library provisioning not currently implemented

**Current Workaround for Multiple Language Requests:**

**Recommended Workflow:**
1. Request movie with Language A profile
2. Wait for download and import to complete
3. In Jellyseerr, delete the REQUEST (not the file)
4. Wait 5 minutes for cleanup script to run
5. Request same movie again with Language B profile

**Alternative - Direct Radarr Management:**
1. Go to Radarr directly
2. Add movie multiple times
3. Each time select different profile and root folder
4. Radarr downloads to separate folders

**Scripts Remaining (After Cleanup):**
- ✅ `backup.sh` - Backup functionality
- ✅ `restore-test.sh` - Restore functionality
- ✅ `init-ldap.sh` - LDAP initialization
- ✅ `ldap-inspect.sh` - LDAP debugging
- ✅ `setup-log-rotation.sh` - Log rotation
- ✅ `jellyfin-cleanup-cron.sh` - Combined cleanup cron job
- ✅ `jellyfin-cleanup.py` - Jellyfin orphan removal (active)
- ✅ `jellyseerr-cleanup.py` - Jellyseerr orphan removal (active)
- ✅ `run-jellyfin-cleanup.sh` - Cleanup wrapper
- ✅ `run-jellyseerr-cleanup.sh` - Cleanup wrapper
- ✅ `sync-arr-profiles.py` - Custom format sync between Radarr/Sonarr
- ✅ `sync-arr-profiles.sh` - Wrapper for custom format sync

**Current Infrastructure Status:**

**Total Containers:** 17
- 2x LDAP (openldap, phpldapadmin)
- 3x Auth (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy)
- 1x Tunnel (cloudflared)
- 1x Web (nginx)
- 6x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr)
- 3x Monitoring (loki, promtail, grafana)

**All Systems Operational:**
- ✅ Unified LDAP authentication
- ✅ SSO via Authelia
- ✅ Complete media automation workflow
- ✅ Automated cleanup (Jellyfin + Jellyseerr) running every 5 minutes
- ✅ Hardlinks working correctly (no space waste)
- ✅ Centralized logging
- ✅ Zero exposed ports

**Next Session Goals:**
- **Future**: Consider forking Jellyseerr to add profile-based duplicate tracking
- **Future**: Explore building MCP server for natural language media requests
- Configure quality profiles and language preferences in Radarr/Sonarr
- Set up automated LDAP backups
- Deploy custom Angular portal
- Consider implementing GitHub Actions CI/CD runner

**Git Status:**
- ✅ Scripts cleaned up and ready to commit
- Suggested commit message: "Clean up experimental Jellyseerr scripts, document duplicate request limitations"

**Research Findings to Remember:**
- Jellyseerr duplicate detection is application-level (JavaScript), not database-level
- Cannot be easily bypassed without custom fork
- Database schema already supports multiple profiles per tmdbId
- Future enhancement would require maintaining custom Jellyseerr build

---

---

### Session 11 - 2025-11-29
**Duration:** ~3 hours
**Focus:** Media stack enhancements, subtitle automation, quality sync, indexer troubleshooting

**Accomplishments:**

- ✅ **Deployed Bazarr for automatic subtitle downloads**
  - Created compose/media/bazarr.yml
  - Configured Caddy reverse proxy (bazarr.Caddyfile)
  - Added to Authelia access control (admins group)
  - Added to Cloudflare Tunnel routing
  - Accessible at: https://bazarr.mykyta-ryasny.dev

- ✅ **Deployed Recyclarr for TRaSH Guides quality sync**
  - Created compose/media/recyclarr.yml
  - Configured recyclarr.yml with Radarr and Sonarr connections
  - Syncs quality definitions from TRaSH Guides
  - Runs on-demand (no web UI, CLI-based)

- ✅ **Deployed FlareSolverr for Cloudflare bypass**
  - Created compose/media/flaresolverr.yml
  - Configured as Prowlarr indexer proxy
  - Successfully bypassing Cloudflare for some indexers (gtorrent.club)
  - Note: 1337x still blocked (they specifically detect headless browsers)

- ✅ **Created radarr-delete-torrent.sh script**
  - Automatically deletes torrent from qBittorrent when movie deleted from Radarr
  - Pure bash implementation (Radarr container lacks Python)
  - Uses jq for JSON parsing
  - Triggered via Radarr Connect custom script

- ✅ **Fixed quality definitions**
  - Radarr: Max 20GB per movie (~140 MB/min)
  - Sonarr: Max 5GB per episode (~110 MB/min)
  - Prevents huge 80GB+ downloads

- ✅ **Fixed Prowlarr indexer issues**
  - Changed minimum seeders from 5 to 1
  - Added Cloudflare DNS (1.1.1.1) to Prowlarr container
  - Configured FlareSolverr as indexer proxy

- ✅ **Fixed Radarr hardlink issue**
  - Enabled `skipFreeSpaceCheckWhenImporting` in Radarr
  - Radarr was blocking imports due to free space check
  - Hardlinks don't need extra space, but Radarr checked anyway
  - Now imports work correctly with hardlinks

- ✅ **Cleaned up deprecated files**
  - Removed webhook.Caddyfile.deprecated

- ✅ **Updated CLAUDE.md**
  - Version 3.1
  - Added Bazarr, Recyclarr, FlareSolverr to service lists
  - Added radarr-delete-torrent.sh to scripts
  - Updated container count from 21 to 24

**Technical Changes:**

**Files Created:**
1. `/opt/homeserver/compose/media/bazarr.yml`
2. `/opt/homeserver/compose/media/recyclarr.yml`
3. `/opt/homeserver/compose/media/flaresolverr.yml`
4. `/opt/homeserver/services/media/recyclarr/config/recyclarr.yml`
5. `/opt/homeserver/services/proxy/caddy/sites/bazarr.Caddyfile`
6. `/opt/homeserver/scripts/radarr-delete-torrent.sh`

**Files Modified:**
1. `/opt/homeserver/docker-compose.yml` - Added new compose includes
2. `/opt/homeserver/services/auth/authelia/configuration.yml` - Added bazarr.mykyta-ryasny.dev to admin rules
3. `/opt/homeserver/services/tunnel/cloudflared/config.yml` - Added bazarr route
4. `/opt/homeserver/compose/media/prowlarr.yml` - Added Cloudflare DNS
5. `/opt/homeserver/compose/media/radarr.yml` - Added scripts volume and QBITTORRENT_URL env
6. `/opt/homeserver/CLAUDE.md` - Updated to version 3.1

**Key Learnings:**

1. **FlareSolverr Limitations**
   - Works for basic Cloudflare protection
   - Some sites (1337x) specifically detect and block headless browsers
   - FlareSolverr uses Chromium to solve challenges
   - Alternative: VPN/SOCKS5 proxy for truly blocked sites

2. **Radarr Free Space Check**
   - Radarr checks free space before import even with hardlinks
   - `skipFreeSpaceCheckWhenImporting: true` bypasses this check
   - Necessary when using hardlinks (no actual space needed)

3. **Prowlarr Indexer Proxies**
   - FlareSolverr configured in Settings → Indexers → Indexer Proxies
   - Can be tagged to apply only to specific indexers
   - Empty tags applies to all indexers

4. **Script Compatibility**
   - Radarr container uses Alpine Linux without Python
   - Must use pure bash/sh for custom scripts
   - jq available for JSON parsing

**Current Infrastructure Status:**

**Total Containers:** 24
- 2x LDAP (openldap, phpldapadmin)
- 3x Auth (postgres-auth, redis-auth, authelia)
- 1x Proxy (caddy)
- 1x Tunnel (cloudflared)
- 1x Web (nginx)
- 2x Portal (portal, hello-world)
- 9x Media (qbittorrent, jellyfin, radarr, sonarr, prowlarr, jellyseerr, bazarr, recyclarr, flaresolverr)
- 3x Monitoring (loki, promtail, grafana)
- 1x CI/CD (github-runner)
- 1x Maintenance (maintenance-cron)

**All Systems Operational:**
- ✅ Unified LDAP authentication
- ✅ SSO via Authelia
- ✅ Complete media automation workflow
- ✅ Automatic subtitle downloads (Bazarr)
- ✅ Quality profile sync from TRaSH Guides (Recyclarr)
- ✅ Cloudflare bypass for supported indexers (FlareSolverr)
- ✅ Automatic torrent cleanup on movie delete
- ✅ Hardlinks working correctly
- ✅ Centralized logging
- ✅ Zero exposed ports

**Access Points:**
- https://bazarr.mykyta-ryasny.dev - Bazarr (subtitles)
- All other services unchanged

**Known Limitations:**
- 1337x indexer still blocked despite FlareSolverr (site-specific detection)
- Workaround: Use alternative indexers (YTS, EZTV, TorrentGalaxy, LimeTorrents)

**Next Session Goals:**
- Configure Bazarr subtitle providers (OpenSubtitles, Subscene, etc.)
- Add Recyclarr to cron for scheduled quality sync
- Consider VPN/SOCKS5 for truly blocked indexers
- Test complete subtitle automation workflow

**Git Status:**
- Multiple files created and modified
- Suggested commit message: "Add Bazarr, Recyclarr, FlareSolverr; fix quality limits and hardlink imports"

---

### Session 12 - 2025-11-29
**Duration:** ~3 hours
**Focus:** Astro Starlight documentation site deployment, migration from markdown docs

**Accomplishments:**

- ✅ **Deployed Astro Starlight documentation site**
  - Created complete docs-site with Astro + Starlight + Tailwind
  - Configured astro.config.mjs with sidebar navigation
  - Set up custom CSS for accent colors (blue theme)
  - Deployed at: https://mykyta-home-server.github.io/homeserver/

- ✅ **Migrated all documentation from /docs/ to docs-site**
  - Converted markdown files to MDX where needed (for Starlight components)
  - Added Astro components: `<Aside>`, `<Steps>`, `<Card>`, `<CardGrid>`
  - Fixed import statements in .md files by renaming to .mdx
  - Deleted old `/docs/` folder after migration confirmed complete

- ✅ **Configured GitHub Actions for Astro builds**
  - Created deploy-docs.yml workflow
  - Changed from `ubuntu-latest` to `self-hosted` runner
  - Fixed `npm ci` to `npm install` (no lock file)
  - Successfully building and deploying to GitHub Pages

- ✅ **Fixed dark mode theme persistence**
  - Issue: Dark mode would reset on page navigation
  - Root cause: Custom CSS overrides conflicted with Starlight's theme system
  - Solution: Simplified custom.css to only override accent colors
  - Let Starlight handle all theme switching natively

- ✅ **Cleaned up stray files**
  - Removed broken symlinks pointing to deleted /docs/ folder
  - Removed .md files accidentally placed in docs-site root
  - Ensured clean project structure

- ✅ **Updated CLAUDE.md with documentation system**
  - Added docs-site directory structure
  - Added documentation creation instructions (md vs mdx, frontmatter)
  - Added Starlight component usage guide
  - Added Documentation Update Protocol

**Technical Details:**

**Files Created:**
1. `/opt/homeserver/docs-site/` - Complete Astro site structure
   - `package.json` - Dependencies
   - `astro.config.mjs` - Site configuration with sidebar
   - `tailwind.config.mjs` - Tailwind configuration
   - `tsconfig.json` - TypeScript configuration
   - `src/styles/custom.css` - Custom accent colors
   - `src/content/docs/` - All documentation pages
   - `src/content/docs/index.mdx` - Homepage with splash hero
   - `src/assets/logo-*.svg` - Site logos

2. `/opt/homeserver/.github/workflows/deploy-docs.yml` - GitHub Actions workflow

**Files Modified:**
1. `/opt/homeserver/CLAUDE.md` - Updated to v3.2 with documentation system

**Files Deleted:**
1. `/opt/homeserver/docs/` - Entire old documentation folder (migrated to docs-site)

**Errors Fixed:**

1. **Starlight social config error**
   - Error: `Expected type "object", received "array"`
   - Fix: Changed from array format `[{icon: 'github', link: 'url'}]` to object `{github: 'url'}`

2. **Missing @astrojs/starlight-tailwind**
   - Error: Build failed on postcss configuration
   - Fix: Added `@astrojs/starlight-tailwind` to package.json dependencies

3. **Runner not picking up jobs**
   - Issue: Self-hosted runner not executing workflows
   - Fix: User enabled "Allow public repositories" in GitHub organization settings

4. **404 on homepage**
   - Issue: No index page at site root
   - Fix: Created `index.mdx` with Starlight splash template and hero section

5. **Dark mode not persisting**
   - Issue: Theme reset on navigation, flashing white
   - Root cause: Custom CSS overriding Starlight's theme variables
   - Fix: Simplified CSS to only set accent colors, removed background/text overrides

6. **Import statements showing as text**
   - Issue: `import { Aside } from '@astrojs/starlight/components'` visible in rendered page
   - Root cause: Files were `.md` but contained JSX component imports
   - Fix: Renamed files with components from `.md` to `.mdx`

**Key Learnings:**

1. **Astro Starlight Theme System**
   - Starlight handles dark/light mode with `data-theme` attribute
   - Only override accent color CSS variables, not background/text colors
   - Starlight persists theme preference in localStorage automatically
   - Fighting the theme system causes bugs (flash, reset on navigation)

2. **MDX vs MD in Astro**
   - `.md` files: Pure markdown, no component imports
   - `.mdx` files: Markdown + JSX component imports
   - Files with `import` statements MUST be `.mdx`
   - Starlight components require MDX format

3. **GitHub Actions Self-Hosted Runners**
   - Organization-level runners require "Allow public repositories" enabled
   - Without this, runner won't pick up jobs from public repos
   - Runner must be online and connected to GitHub

4. **Starlight Social Config**
   - Social links use object format, not array
   - Format: `social: { github: 'url', discord: 'url' }`
   - Breaking change from some Starlight examples online

5. **Astro Build on Self-Hosted Runner**
   - Use `npm install` instead of `npm ci` without lock file
   - Runner needs Node.js 20+ for Astro 5.x
   - Working directory must be set for all npm commands

**Documentation Site Structure:**
```
docs-site/
├── astro.config.mjs          # Site config with sidebar
├── package.json              # Dependencies
├── tailwind.config.mjs       # Tailwind setup
├── tsconfig.json             # TypeScript config
└── src/
    ├── assets/               # Logos
    ├── content/
    │   └── docs/             # Documentation pages
    │       ├── index.mdx     # Homepage
    │       ├── guides/       # How-to guides
    │       ├── reference/    # Quick references
    │       └── setup/        # Setup guides
    └── styles/
        └── custom.css        # Accent color overrides
```

**Access Points:**
- https://mykyta-home-server.github.io/homeserver/ - Documentation site (live)
- All other services unchanged

**Current Infrastructure Status:**

**Total Containers:** 24 (unchanged from Session 11)

**All Systems Operational:**
- ✅ Documentation site deployed on GitHub Pages
- ✅ Automated builds via self-hosted GitHub runner
- ✅ Dark/light mode working correctly
- ✅ All previous services operational

**Git Status:**
- Multiple files created (docs-site)
- Multiple files deleted (old docs folder)
- CLAUDE.md updated
- Suggested commit message: "Deploy Astro Starlight documentation site, migrate from markdown docs"

---

## Session 13 - 2025-11-30: Documentation Site Visual Enhancements

**Focus:** Improve Mermaid diagram visibility, styling, and interactivity

### Accomplishments

1. **Mermaid Diagram Styling**
   - Added pastel color palette with light/dark mode support
   - Implemented rounded corners (12px radius) on all diagram nodes
   - Added hover effects with subtle shadows
   - Applied consistent styling across flowcharts and sequence diagrams
   - Used `direction LR` inside subgraphs for compact layouts

2. **Click-to-Zoom Modal**
   - Built full-screen modal overlay for diagram expansion (90vw x 85vh)
   - Fixed SVG cloning issues (using `cloneNode(true)`)
   - Fixed modal caching bug (recreates modal fresh on each click)
   - Added close button (×) and ESC key support
   - Applied same pastel styling to modal view via `.mermaid-modal` selectors

3. **UI Improvements**
   - Reduced "On this page" right sidebar from default to 10rem
   - Added "Click to expand" hint text at bottom center of diagrams
   - Improved content area width with media queries

4. **Diagram Layouts Redesigned (introduction.mdx)**
   - System Architecture: Nested subgraphs (Internet → Server → Services)
   - Media Automation Flow: 5-stage pipeline (Request → Search → Download → Process → Stream)
   - Authentication Flow: Complete 6-participant sequence diagram
   - Docker Network Architecture: Compact TB layout with `direction LR` in subgraphs

### Technical Details

**Files Modified:**
- `docs-site/src/styles/custom.css` - All Mermaid styling and modal CSS
- `docs-site/astro.config.mjs` - Modal zoom JavaScript in head config
- `docs-site/src/content/docs/guides/introduction.mdx` - All 4 diagrams

**Key CSS Variables:**
```css
/* Light mode */
--mermaid-primary: #a8d5ff;      /* Node backgrounds */
--mermaid-primary-text: #1a365d; /* Node text */
--mermaid-note: #ffe4f3;         /* Subgraph backgrounds */
--mermaid-line: #94a3b8;         /* Edges and borders */

/* Dark mode - adjusted for visibility */
--mermaid-primary: #1e4976;
--mermaid-primary-text: #93c5fd;
```

**Modal Implementation Key Points:**
- Uses `astro:page-load` event for SPA navigation support
- 1500ms delay ensures Mermaid SVGs are rendered before attaching handlers
- Removes SVG width/height attributes for proper scaling in modal
- Modal recreated fresh each click to avoid stale/cached content

### Issues Resolved

| Issue | Cause | Fix |
|-------|-------|-----|
| Modal shows empty/old diagram | Modal was reused, SVG stale | Recreate modal fresh each click |
| Modal shows unstyled diagram | CSS selectors only for `.mermaid` | Add `.mermaid-modal` to all rules |
| SVG not scaling in modal | Hardcoded width/height attrs | Remove attrs on clone |
| "Click to expand" wrong position | Used margin instead of absolute | Absolute positioning at bottom |
| Diagrams too linear/wide | LR layout for all elements | Use `direction LR` inside TB subgraphs |

### Key Learnings

1. **Mermaid Styling in Modals**: CSS selectors must include both `.mermaid` and `.mermaid-modal` for styles to apply in expanded view

2. **SVG Cloning**: Use `cloneNode(true)` for deep copy, remove dimension attributes for responsive scaling

3. **Modal Caching**: Always create modal elements fresh to avoid showing stale content

4. **Compact Layouts**: Use `flowchart TB` with `direction LR` inside subgraphs for square-ish layouts

### Access Points

- https://mykyta-ryasny.github.io/homeserver/ - Documentation site (live)
- Diagrams now have click-to-expand functionality
- All other services unchanged

### Git Status

- Committed and pushed: "Fix modal styling, restore detailed diagrams, shrink sidebar"
- Deployment via GitHub Actions to GitHub Pages (automatic on push to main)

---

## Session 14 - 2025-11-30: Angular Portal Development

**Focus:** Build role-based dashboard portal with theme system and permission-based UI

### Accomplishments

1. **GitHub CLI Integration**
   - Installed and authenticated `gh` CLI on server
   - Can now access private repos: `homeserver-portal`, `user-management-api`
   - Enables fetching/reviewing code without cloning locally

2. **Tailwind v4 Dark Mode Setup**
   - Learned Tailwind v4 uses `@import "tailwindcss"` (not `@tailwind` directives)
   - `tailwind.config.js` is ignored in v4 - configuration done in CSS
   - Added `@custom-variant dark (&:where(.dark, .dark *));` for class-based toggle
   - Created CSS variables for theme colors in `styles.css`

3. **Custom Theme Utility Classes (No Duplication Approach)**
   - Created reusable classes: `bg-theme-primary`, `text-theme-primary`, `border-theme`, etc.
   - Colors auto-switch between light/dark via CSS variables
   - Single source of truth - change colors in one place

4. **ThemeService with Angular Signals**
   - Signal-based state management (`signal<Theme>`)
   - Persists preference to localStorage
   - Respects system preference as fallback
   - Toggle adds/removes `dark` class on `<html>`

5. **AuthService with Angular Signals**
   - Reactive user state with signals and computed values
   - `hasPermission()`, `isInGroup()`, `isAdmin()` methods
   - Fetches user info from `/api/me` endpoint

6. **Portal Components Built**
   - `LayoutComponent` - Shell with header, sidebar, router outlet
   - `HeaderComponent` - Logo (links to home), user info, theme toggle, logout
   - `SidebarComponent` - Permission-based service sections
   - `HomeComponent` - Welcome message and access info cards
   - `NotFoundComponent` - 404 page with back button

7. **Permission-Based UI**
   - Sidebar sections filtered by permissions:
     - `access:media` → Jellyfin, Jellyseerr
     - `access:admin_tools` → Radarr, Sonarr, Prowlarr, qBittorrent, Bazarr
     - `access:monitoring` → Grafana
   - Admin badge shown in header for admin users

8. **Mobile Navigation Design**
   - Designed bottom navigation for mobile (Option C)
   - Desktop: Traditional sidebar
   - Mobile: Fixed bottom bar with icons + "More" menu for admin tools

### Technical Details

**Portal Stack:**
- Angular 19 (standalone components)
- Tailwind CSS v4
- Signals for state management
- No separate HTML files (inline templates)

**Theme CSS Structure:**
```css
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));

@layer base {
  :root { /* light mode variables */ }
  .dark { /* dark mode variables */ }
}

@layer utilities {
  .bg-theme-primary { background-color: var(--color-bg-primary); }
  /* ... other utility classes */
}
```

**Key Files Modified (in homeserver-portal repo):**
- `src/styles.css` - Theme variables and utility classes
- `src/app/core/services/auth.service.ts` - Signals-based auth
- `src/app/core/services/theme.service.ts` - Theme toggle
- `src/app/shared/components/layout/layout.component.ts`
- `src/app/shared/components/header/header.component.ts`
- `src/app/shared/components/sidebar/sidebar.component.ts`
- `src/app/features/home/home.component.ts`
- `src/app/features/not-found/not-found.component.ts`

### Iframe Analysis for Service Embedding

Checked `X-Frame-Options` headers for all services:

| Service | Header | Embeddable? |
|---------|--------|-------------|
| Jellyfin | None | ✅ Yes |
| Jellyseerr | None | ✅ Yes |
| Radarr | DENY | ❌ No |
| Sonarr | DENY | ❌ No |
| Prowlarr | DENY | ❌ No |
| qBittorrent | DENY | ❌ No |
| Bazarr | DENY | ❌ No |
| Grafana | SAMEORIGIN | ❌ No |

Decision: Use links instead of iframes for now. Can strip headers in Caddy later if needed.

### Session Sync Investigation

**Current Setup:**
- Jellyfin uses LDAP plugin (already configured with 3 users)
- Jellyseerr uses Jellyfin for auth (`mediaServerLogin: true`)
- Sessions are separate - logout doesn't sync

**Better Solution Identified:**
- Authelia OIDC integration for Jellyfin
- Uses SSO plugin instead of LDAP plugin
- Enables true single sign-on and logout sync
- Documentation: https://www.authelia.com/integration/openid-connect/clients/jellyfin/

### Next Session: OIDC Setup

Planned tasks:
1. Enable OIDC identity provider in Authelia config
2. Install Jellyfin SSO plugin (replace LDAP plugin)
3. Configure OIDC client for Jellyfin
4. Create LDAP groups: `jellyfin-users`, `jellyfin-admins`
5. Test SSO login flow
6. Configure Jellyseerr to inherit Jellyfin OIDC

### Key Learnings

1. **Tailwind v4 Breaking Changes**
   - `tailwind.config.js` no longer used by default
   - Use `@custom-variant` in CSS for dark mode class strategy
   - Use `@theme` directive for custom colors (or CSS variables directly)

2. **Angular Signals Benefits**
   - Cleaner than BehaviorSubject for simple state
   - No `| async` pipe needed in templates
   - `computed()` for derived values

3. **Authelia Cookie Scope**
   - Set on `.mykyta-ryasny.dev` (all subdomains)
   - Enables SSO across services protected by Authelia
   - But doesn't help with services that have their own auth (Jellyfin)

### Git Status

Portal branch: `feat/small_fixes_defaul_ui`
Commits made during session for theme and layout implementation.

---

**End of Session Status Notes**

_This file should be updated at the end of each session with new progress, decisions, and blockers._
---

## Session 15 - 2025-12-01: Authentik SSO Migration & Complete Auth Stack Replacement

**Duration:** ~6 hours (split across multiple sub-sessions)
**Focus:** Migrate from Authelia/LDAP/User-Management to Authentik SSO with auto-login, custom branding, and confirmation-free logout

### Accomplishments

✅ **Complete Authentik Setup**
- Deployed Authentik SSO (server + worker containers)
- Configured PostgreSQL and Redis integration (reused existing auth stack databases)
- Set up forward auth with Caddy reverse proxy
- Created proxy provider for all services

✅ **Auto-SSO for Jellyseerr**
- Implemented `/sso` endpoint serving `auto-sso.html`
- Auto-fetches Jellyseerr's OIDC login URL and redirects
- Updated portal repository to link to `/sso` path instead of root
- Includes loop detection and fallback to manual login

✅ **Custom Authentik Branding**
- Created `services/auth/authentik/branding/custom.css`
- Matched portal's design system (light/dark mode with `prefers-color-scheme`)
- Custom colors, rounded borders (8px), centered login card
- Single-step login page (username + password together)

✅ **Confirmation-Free Logout**
- Created custom `direct-logout` flow (Stage Configuration designation)
- Updated ALL service logout endpoints across 7 Caddyfiles
- Bypassed Authentik's automatic confirmation stage insertion
- Immediate session destruction + redirect to login

✅ **Complete Legacy Auth Removal**
- Stopped and removed containers: authelia, openldap, phpldapadmin, user-management
- Deleted compose files: `authelia.yml`, `ldap.yml`, `user-management.yml`
- Removed `services/auth/authelia/` and `services/auth/ldap/` directories
- Deleted `services/proxy/caddy/sites/auth.Caddyfile`
- Removed `authelia_auth` snippet from main Caddyfile
- Removed `auth.mykyta-ryasny.dev` route from cloudflared config

✅ **Documentation Cleanup**
- Deleted `docs-site/src/content/docs/guides/ldap.mdx`
- Removed LDAP Guide from astro.config.mjs sidebar
- Updated docker-compose.yml service list comments
- Updated CLAUDE.md v3.6:
  - Changed container count: 24 → 22
  - Changed compose files: 21 → 18
  - Updated Current Infrastructure table
  - Updated Network Architecture (auth → internal)
  - Updated Directory Structure
  - Updated Service list in Quick Reference
  - Updated Version History with migration details
- Marked `authentication.json` Grafana dashboard for update

### Technical Implementation

**Authentik Configuration:**
- **Image:** `ghcr.io/goauthentik/server:2025.10.2`
- **Containers:** authentik-server (port 9000), authentik-worker
- **Networks:** internal (database access), proxy (Caddy forward auth)
- **Volumes:** media, templates, branding (CSS), Docker socket (worker)

**Auto-SSO Pattern:**
```javascript
// /services/proxy/caddy/sites/auto-sso.html
fetch('/api/v1/auth/oidc/login/authentik')
  .then(response => response.json())
  .then(data => window.location.href = data.redirectUrl)
```

**Caddyfile Logout Pattern:**
```caddyfile
@logout path /logout
redir @logout "https://sso.mykyta-ryasny.dev/if/flow/direct-logout/" 302
```

**Services Updated with Logout:**
- Portal (`home.mykyta-ryasny.dev`)
- Radarr (`movies.mykyta-ryasny.dev`)
- Sonarr (`tv.mykyta-ryasny.dev`)
- Prowlarr (`indexers.mykyta-ryasny.dev`)
- Jellyseerr (`requests.mykyta-ryasny.dev`)
- Bazarr (`bazarr.mykyta-ryasny.dev`)
- Grafana (`monitor.mykyta-ryasny.dev`)

### Key Learnings

1. **Authentik Flow System Complexity:**
   - Flow "Designation" determines automatic stage injection
   - "Invalidation" flows auto-insert confirmation stages (unavoidable)
   - "Stage Configuration" designation bypasses user-facing stages
   - Dynamic in-memory stages can't be removed from UI
   - Solution: Bypass flows entirely with client-side cookie clearing

2. **Forward Auth Header Mapping:**
   - Authentik uses `X-Authentik-*` headers (capitalized)
   - Must explicitly copy headers in Caddy forward_auth block
   - Header names are case-sensitive
   - Portal needs headers passed as response headers for JavaScript access

3. **OIDC Auto-Login Pattern:**
   - Fetch JSON endpoint for `redirectUrl`
   - Session storage prevents infinite loops
   - Fallback to manual `/login` after failed attempts
   - Critical for seamless user experience

4. **Cloudflare Tunnel + Caddy Integration:**
   - Tunnel → Caddy (HTTPS with origin certs)
   - `noTLSVerify: true` required for self-signed origin certs
   - `originServerName` required for proper SNI
   - All services routed through single Caddy instance

5. **Docker Compose Profile Architecture:**
   - Default profile: infrastructure + auth (6 containers)
   - Profiles enable selective service startup
   - Auth stack shared by all profiles (PostgreSQL, Redis)
   - Authentik containers always run (no profile designation)

### Files Created

- `compose/auth/authentik.yml` - Authentik server + worker configuration
- `services/auth/authentik/branding/custom.css` - Custom login page styling
- `services/proxy/caddy/sites/authentik.Caddyfile` - SSO portal config
- `services/proxy/caddy/sites/auto-sso.html` - Jellyseerr auto-login page
- `services/proxy/caddy/sites/logout.html` - Client-side logout (unused, kept for reference)

### Files Modified

- `docker-compose.yml` - Replaced legacy auth includes with authentik.yml
- `services/proxy/caddy/Caddyfile` - Removed authelia_auth, kept authentik_auth
- `services/tunnel/cloudflared/config.yml` - Removed auth.mykyta-ryasny.dev
- `services/proxy/caddy/sites/portal.Caddyfile` - Added logout handler, updated auth headers
- `services/proxy/caddy/sites/media.Caddyfile` - Updated 5 services (logout handlers)
- `services/proxy/caddy/sites/bazarr.Caddyfile` - Added logout handler
- `services/proxy/caddy/sites/monitoring.Caddyfile` - Added logout handler
- `CLAUDE.md` - Updated to v3.6 with Authentik references
- `docs-site/astro.config.mjs` - Removed LDAP Guide from sidebar
- `compose/media/jellyseerr.yml` - Already using preview-OIDC image (no changes)

### Files Deleted

- `compose/auth/authelia.yml`
- `compose/auth/ldap.yml`
- `compose/auth/user-management.yml`
- `services/proxy/caddy/sites/auth.Caddyfile`
- `services/auth/authelia/` (directory + contents)
- `services/auth/ldap/` (directory + contents)
- `docs-site/src/content/docs/guides/ldap.mdx`

### Remaining Tasks

**Manual Updates Needed:**
1. **Grafana Dashboards:**
   - `services/monitoring/grafana/provisioning/dashboards/authentication.json`
   - Replace Authelia/LDAP panels with Authentik panels
   - Update container queries: `authelia`/`openldap` → `authentik-server`/`authentik-worker`
   - `home.json` - Update Authelia status panel to Authentik

2. **Architecture Documentation:**
   - `.claude/architecture.md` - Update auth flow diagrams
   - `.claude/technical_specs.md` - Update auth stack specifications

### Current Status

✅ **Production Infrastructure:**
- **22 containers** running (down from 24)
- **18 compose files** (down from 21)
- **Authentik SSO** fully operational
- **All services** protected with forward auth
- **Jellyseerr** auto-SSO working
- **Custom branding** applied
- **Logout flows** working (no confirmation)

⚠️ **Pending:**
- Grafana dashboards still reference old auth services
- Architecture documentation needs Authentik diagrams
- User-Management API container gone (was used by portal admin panel)

### Session Flow Summary

1. **Initial Setup** - Deployed Authentik, configured forward auth
2. **Auto-SSO Implementation** - Built auto-login flow for Jellyseerr
3. **Custom Branding** - Styled login page to match portal
4. **Logout Confirmation Battle** - Tried multiple approaches to remove confirmation:
   - Attempted to modify default-invalidation-flow
   - Tried creating custom flow with different designations
   - Discovered Authentik's automatic stage injection behavior
   - Solution: Created `direct-logout` flow with Stage Configuration designation
5. **Legacy Removal** - Systematically removed all Authelia/LDAP components
6. **Documentation Update** - Updated CLAUDE.md, cleaned up references

### Commits

To be created in next step with comprehensive message documenting the migration.


---

### Session 13 - 2025-12-15
**Duration:** ~2 hours
**Focus:** Docker Image Version Pinning & Update Monitoring System

### Accomplishments

✅ **Pinned Docker Images (11 services):**
- Replaced all `latest` tags with specific versions for production stability
- **Media stack:** flaresolverr (v3.4.5), bazarr (v1.5.3-ls325), sonarr (4.0.16.2944-ls298), prowlarr (2.3.0.5236-ls132), radarr (6.0.4.10291-ls287), jellyfin (10.11.3ubu2404-ls8), recyclarr (7.4.1), qbittorrent (5.1.4-r0-ls427)
- **Infrastructure:** alpine (3.22), caddy (2), cloudflared (2025.11.1)
- Portal image remains on `latest` (custom CI/CD image)

✅ **Created Update Monitoring System:**
- Built `scripts/check-updates.py` - Automated version checker
- Queries Docker Hub, GHCR, and LSCR registries for newer versions
- Detects LinuxServer.io build number increments (e.g., `-ls298` → `-ls300`)
- Logs structured JSON to stdout for Loki ingestion
- Added to maintenance-cron: runs daily at 2 AM

✅ **Created Docker Updates Grafana Dashboard:**
- New dedicated dashboard: `docker-updates.json`
- **4 stat panels:**
  - Updates Available (green/yellow/orange thresholds)
  - Total Images Monitored
  - Last Check Status (OK/No Data)
  - Check Failures (auth issues)
- **Log viewer:** JSON-parsed logs with level filtering (DEBUG/INFO/WARNING/ERROR)
- **Pinned versions reference:** Shows current `image:version` for all monitored images
- 30-second auto-refresh

✅ **Standardized Grafana Navigation:**
- Updated all 6 dashboards with consistent 3x3 navigation grid
- **Row 1:** Home, Infrastructure, Media Stack
- **Row 2:** Authentication, Operations, Docker Updates
- Each tab: 8 columns wide (24÷3=8)
- Fixed duplicate navigation panels in home dashboard

### Technical Implementation

**1. Version Detection Logic:**
```python
# LinuxServer.io images use -lsXXX build numbers
if "-ls" in current_version:
    current_ls = int(re.search(r'-ls(\d+)', current_version).group(1))
    latest_ls = max([int(re.search(r'-ls(\d+)', t).group(1)) 
                   for t in tags if re.search(r'-ls(\d+)', t)], default=current_ls)
    if latest_ls > current_ls:
        # Update available!
```

**2. JSON Logging for Loki:**
```python
log_entry = {
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "level": "INFO",
    "script": "check-updates",
    "message": "Update available",
    "image": "lscr.io/linuxserver/sonarr",
    "current_version": "4.0.16.2944-ls298",
    "latest_version": "4.0.16.2944-ls300",
    "update_available": True
}
print(json.dumps(log_entry), flush=True)
```

**3. Grafana LogQL Queries:**
```logql
# Updates available count
sum(count_over_time({container="maintenance-cron"} |= "check-updates" | json | update_available="true" [24h]))

# Current pinned versions
{container="maintenance-cron"} |= "check-updates" | json | image!="" | line_format "{{.image}}:{{.current_version}}"
```

### Key Learnings

1. **Version Pinning Benefits:**
   - **Prevents breaking changes** from automatic `latest` pulls
   - **Enables controlled updates** - you decide when to upgrade
   - **Audit trail** - know exactly what version is running
   - **Rollback safety** - easy to revert to known-good version
   - **Production best practice** - never use `latest` in prod

2. **Registry API Limitations:**
   - **GHCR (GitHub Container Registry):** Requires authentication for tag listing
   - **LSCR (LinuxServer.io):** Requires authentication (401 errors)
   - **Docker Hub:** Works without auth for public images
   - **Solution:** Script handles auth failures gracefully, logs warnings
   - **Future:** Add registry tokens via environment variables

3. **LinuxServer.io Versioning Pattern:**
   - Format: `{app_version}-ls{build_number}`
   - Example: `4.0.16.2944-ls298`
   - **App version:** Upstream software version
   - **Build number:** LinuxServer's container build iteration
   - Build number increments indicate image updates (security patches, base image updates)
   - Comparing `-ls` numbers is reliable update detection method

4. **Grafana Dashboard Provisioning:**
   - Dashboards must have correct file permissions (644)
   - UID must match for navigation links (`/d/{uid}`)
   - Transparent text panels for navigation (consistent positioning)
   - JSON structure sensitive to panel positioning (gridPos.y)

5. **Structured Logging Benefits:**
   - **JSON logging** makes Loki queries powerful
   - **Field extraction:** `| json` operator parses fields automatically
   - **Filtering:** Can filter by `update_available`, `level`, `image`, etc.
   - **Aggregation:** `count_over_time()` works across JSON fields
   - **Better than grep:** Searchable by structured fields, not just text

### Files Created

**Scripts:**
- `scripts/check-updates.py` - Update checker (JSON logging, registry queries)

**Grafana:**
- `services/monitoring/grafana/provisioning/dashboards/docker-updates.json` - Update monitoring dashboard

### Files Modified

**Compose files (11):**
- `compose/media/flaresolverr.yml` - Pinned to v3.4.5
- `compose/media/bazarr.yml` - Pinned to v1.5.3-ls325
- `compose/media/sonarr.yml` - Pinned to 4.0.16.2944-ls298
- `compose/media/prowlarr.yml` - Pinned to 2.3.0.5236-ls132
- `compose/media/radarr.yml` - Pinned to 6.0.4.10291-ls287
- `compose/media/jellyfin.yml` - Pinned to 10.11.3ubu2404-ls8
- `compose/media/recyclarr.yml` - Pinned to 7.4.1
- `compose/media/qbittorrent.yml` - Pinned to 5.1.4-r0-ls427
- `compose/maintenance/cron.yml` - Pinned to alpine:3.22
- `compose/infrastructure/proxy.yml` - Pinned to caddy:2
- `compose/infrastructure/tunnel.yml` - Pinned to cloudflare/cloudflared:2025.11.1

**Cron:**
- `services/maintenance/cron/crontab` - Added update checker (daily at 2 AM)

**Grafana Dashboards (6):**
- `services/monitoring/grafana/provisioning/dashboards/home.json` - Updated navigation, removed duplicates
- `services/monitoring/grafana/provisioning/dashboards/infrastructure.json` - Updated navigation
- `services/monitoring/grafana/provisioning/dashboards/media-stack.json` - Updated navigation
- `services/monitoring/grafana/provisioning/dashboards/authentication.json` - Updated navigation
- `services/monitoring/grafana/provisioning/dashboards/operations.json` - Updated navigation

### Current Status

✅ **All Docker images pinned to specific versions**
✅ **Automated update monitoring running (daily at 2 AM)**
✅ **Grafana dashboard showing update status**
✅ **Consistent navigation across all dashboards**

📊 **Monitoring Coverage:**
- 20 images monitored
- 10 successfully checking for updates (Docker Hub)
- 10 requiring authentication (GHCR/LSCR) - gracefully handled

### Commits

Pending commit with message documenting version pinning and update monitoring implementation.

### Next Steps (Future Sessions)

1. **When updates are available:**
   - Check Docker Updates dashboard
   - Review changelog for breaking changes
   - Update compose file version tags
   - Test updated service
   - Commit version bump

2. **Registry authentication (optional):**
   - Add GHCR token to check GitHub packages
   - Add LSCR token to check LinuxServer images
   - Improves coverage from 50% to 100%

3. **Update automation (future enhancement):**
   - Create update approval workflow
   - Auto-create GitHub issues for available updates
   - Track update age (how old is current version?)
   - Grafana alerts for critical updates

