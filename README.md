# Home Server Automation Project

A comprehensive home server with AI-powered natural language automation, built as a learning project to deeply understand infrastructure, containerization, networking, and automation.

## 🎯 Project Status

**Current Phase:** Production Infrastructure Deployed
**Public Website:** https://mykyta-ryasny.dev ✅ LIVE
**Last Updated:** 2025-11-22

### Infrastructure Running:
- ✅ Caddy reverse proxy with modular configuration
- ✅ Cloudflare Tunnel with Full SSL encryption
- ✅ Docker Compose orchestration
- ✅ Tailscale VPN for secure remote access

---

## 📁 Project Structure

```
/opt/homeserver/
├── CLAUDE.md                    # Core instructions for Claude AI assistant
├── README.md                    # This file - project overview
├── docker-compose.yml           # Main service orchestration
│
├── docs/                        # 📚 USER DOCUMENTATION
│   ├── README.md               # Documentation index
│   ├── DOCKER_INSTALLATION_GUIDE.md
│   ├── DOCKER_QUICK_COMMANDS.md
│   ├── ZSH_SETUP_SOLUTION.md
│   ├── QOL_TOOLS_GUIDE.md
│   └── setup-quality-of-life.sh
│
├── sessions/                    # 📋 SESSION NOTES (for Claude context)
│   ├── README.md               # Session notes index
│   ├── SESSION_STATUS.md       # Master session log (source of truth)
│   ├── NEXT_SESSION.md         # Quick start guide
│   └── SESSION_X_SUMMARY.md    # Individual session summaries
│
├── .claude/                     # 🏗️ ARCHITECTURE DOCUMENTATION (for Claude)
│   ├── architecture.md         # System architecture
│   ├── technical_specs.md      # Technical specifications
│   ├── api_documentation.md    # API documentation
│   ├── code_examples.md        # Code templates
│   └── commands/               # Claude Code slash commands
│
└── services/                    # 🐳 SERVICE CONFIGURATIONS
    ├── caddy/                  # Reverse proxy
    │   ├── Caddyfile
    │   ├── README.md
    │   ├── sites/              # Modular service configs
    │   └── certs/              # Cloudflare Origin Certificates
    ├── cloudflared/            # Cloudflare Tunnel
    │   ├── config.yml
    │   └── credentials.json
    └── hello-world/            # Example service
        └── index.html
```

---

## 🚀 Quick Start

### For the User (You)

**Starting a new work session:**
1. Read [sessions/SESSION_STATUS.md](sessions/SESSION_STATUS.md) to see current progress
2. Check [sessions/NEXT_SESSION.md](sessions/NEXT_SESSION.md) for what to do next
3. Reference [docs/](docs/) for setup guides and commands

**Adding a new service:**
1. Read [docs/adding-services.md](docs/adding-services.md)
2. Use [services/caddy/sites/_template.caddy](services/caddy/sites/_template.caddy) as template
3. Follow the modular pattern established

**Need help?**
- Quick commands: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)
- Docker commands: [docs/DOCKER_QUICK_COMMANDS.md](docs/DOCKER_QUICK_COMMANDS.md)
- Tool usage: [docs/QOL_TOOLS_GUIDE.md](docs/QOL_TOOLS_GUIDE.md)

### For Claude AI Assistant

**Starting a new session:**
```
Read CLAUDE.md for core instructions, then read sessions/SESSION_STATUS.md
to understand project progress and current state.
```

**Ending a session:**
Follow the "End of Session Protocol" in [CLAUDE.md](CLAUDE.md) to update:
- `sessions/SESSION_STATUS.md` with session summary
- `sessions/NEXT_SESSION.md` with updated status
- Any relevant documentation that changed

---

## 📖 Documentation Guide

### 1. **User Documentation** ([docs/](docs/))
**Purpose:** Self-service guides for independent setup and maintenance

**Key Files:**
- [DOCKER_INSTALLATION_GUIDE.md](docs/DOCKER_INSTALLATION_GUIDE.md) - Complete Docker setup
- [DOCKER_QUICK_COMMANDS.md](docs/DOCKER_QUICK_COMMANDS.md) - Command cheat sheet
- [QOL_TOOLS_GUIDE.md](docs/QOL_TOOLS_GUIDE.md) - Productivity tools reference
- [ZSH_SETUP_SOLUTION.md](docs/ZSH_SETUP_SOLUTION.md) - Shell configuration

**Use when:** Setting up new environments, troubleshooting, or quick command reference

### 2. **Session Notes** ([sessions/](sessions/))
**Purpose:** Track project progress, decisions, and learning

**Key Files:**
- [SESSION_STATUS.md](sessions/SESSION_STATUS.md) - **Master log** (always read first!)
- [NEXT_SESSION.md](sessions/NEXT_SESSION.md) - Quick start for next session
- Individual session summaries for detailed history

**Use when:** Starting/ending sessions, understanding project history, planning next steps

### 3. **Architecture Documentation** ([.claude/](.claude/))
**Purpose:** Technical specifications and system design

**Key Files:**
- `architecture.md` - Overall system architecture
- `technical_specs.md` - Detailed technical specifications
- `docs/adding-services.md` - Service addition guide

**Use when:** Understanding design decisions, adding services, making architectural changes

### 4. **Core Instructions** ([CLAUDE.md](CLAUDE.md))
**Purpose:** Master prompt and guidelines for Claude AI assistant

**Use when:** Configuring Claude, understanding project goals and constraints

---

## 🛠️ Technology Stack

- **OS:** Ubuntu Server 22.04 LTS
- **Containerization:** Docker + Docker Compose
- **Reverse Proxy:** Caddy (automatic HTTPS, modular configuration)
- **Security:** Cloudflare Tunnel (zero exposed ports)
- **Remote Access:** Tailscale VPN
- **Future:** MCP Server + Telegram Bot for natural language control

---

## 🎓 Project Philosophy

This is a **learning project** focused on:
- **Understanding WHY**, not just copying commands
- **Best practices** from the start (Infrastructure as Code, security-first)
- **Extensibility** - easy to add new services without refactoring
- **Documentation** - everything explained and reproducible

**Not focused on:**
- Speed over understanding
- Quick hacks or technical debt
- Cutting corners on security

---

## 🔒 Security Architecture

```
User (HTTPS)
    ↓
Cloudflare Edge (CDN + DDoS protection)
    ↓
Encrypted Tunnel (no exposed ports!)
    ↓
Caddy Reverse Proxy (Cloudflare Origin Certs)
    ↓
Docker Containers (isolated services)
```

**Key Security Features:**
- Zero ports exposed to internet (everything through Cloudflare Tunnel)
- End-to-end encryption (Full SSL mode)
- Container isolation
- Secrets management (no hardcoded credentials)
- Tailscale VPN for secure SSH access

---

## 📊 Infrastructure Details

| Item | Value |
|------|-------|
| **Server** | Ubuntu Server 22.04 LTS on Hyper-V VM |
| **Resources** | 6 vCPU, 16GB RAM, 200GB disk |
| **Network** | 192.168.1.200 (bridged networking) |
| **Domain** | mykyta-ryasny.dev |
| **Tunnel ID** | 07fbc124-6f0e-40c5-b254-3a1bdd98cf3c |
| **SSL Mode** | Full (Cloudflare Origin Certificates) |

---

## 🚦 Current Services

### Production Services:
1. **Caddy** - Reverse proxy with automatic HTTPS
2. **Cloudflared** - Cloudflare Tunnel (4 active connections)
3. **hello-world** - Example website at mykyta-ryasny.dev

### Planned Services:
- Plex Media Server
- qBittorrent
- Homepage Dashboard
- Jellyfin
- Custom portfolio website
- MCP Server for automation
- Telegram Bot interface

---

## 📝 Common Commands

```bash
# Navigate to project
cd /opt/homeserver

# View running services
docker ps
docker compose ps

# Check service logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Deploy/update services
docker compose up -d

# Access lazydocker TUI
lazydocker

# Git status
git status

# View files with syntax highlighting
bat filename
```

**More commands:** See [docs/DOCKER_QUICK_COMMANDS.md](docs/DOCKER_QUICK_COMMANDS.md)

---

## 🎯 Next Steps

See [sessions/NEXT_SESSION.md](sessions/NEXT_SESSION.md) for detailed next steps.

**Suggested priorities:**
1. Deploy additional services (Plex, qBittorrent, portfolio website)
2. Set up monitoring (Grafana, Prometheus)
3. Implement automated backups
4. Begin MCP server development for automation

---

## 📚 Additional Resources

### Official Documentation:
- [Docker Documentation](https://docs.docker.com/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

### Project Documentation:
- All documentation is in this repository
- Architecture docs in `.claude/`
- User guides in `docs/`
- Session history in `sessions/`

---

## 💡 Tips for Success

1. **Always read `sessions/SESSION_STATUS.md` first** when starting a new session
2. **Document as you go** - future you will thank you
3. **Commit working configurations** to Git frequently
4. **Test in small steps** - easier to debug
5. **Use the guides** in `docs/` - they're there to help you work independently
6. **Ask "why"** - this is a learning project, understand the concepts

---

**Project Start Date:** November 20, 2024
**Last Updated:** November 22, 2025
**Maintained By:** Mykyta
**Infrastructure:** PoC on Hyper-V VM (migration to physical server planned)

---

**Ready to build something amazing!** 🚀
