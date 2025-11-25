---
description: "Comprehensive deep dive into the home server automation project"
---

Provide a comprehensive, detailed exploration of the home server automation project covering all technical aspects.

Reference and synthesize information from:
@.claude/architecture.md
@.claude/technical_specs.md

Include detailed sections for:
1. **Executive Summary** - Project overview and goals
2. **Complete Architecture** - All components and their interactions
3. **Technology Decisions** - Why each technology was chosen with trade-offs
4. **Security Architecture** - Defense in depth strategy, all security layers
5. **Service Specifications** - Detailed breakdown of Plex, qBittorrent, Minecraft
6. **Automation Layer** - MCP Server and Telegram Bot implementation details
7. **Network Architecture** - Internal Docker network topology
8. **Data Flows** - Step-by-step examples (external access, downloads, automation)
9. **Extensibility** - How to add new services and capabilities
10. **Development & Maintenance** - Project structure, troubleshooting, procedures
11. **Learning Resources** - Links to official documentation

This is the comprehensive technical reference guide for the entire project - include all diagrams, code examples, and architectural decisions.

---

## Project Philosophy & Approach

### Learning vs. Speed

This project prioritizes **deep understanding** over rapid deployment:

- **Why things work**, not just how to configure them
- **Best practices from day one**, not quick hacks
- **Extensible architecture**, not hard-coded solutions
- **Security first**, not as an afterthought

### Developer Profile
- 2 years development experience
- Solo personal project
- Values comprehensive explanations with references
- Prefers Infrastructure as Code
- Working methodically through each concept

---

## Architectural Deep Dive

### Data Flow: External Access to Plex

```
1. User visits https://plex.yourdomain.com
2. DNS resolves to Cloudflare nameservers
3. Cloudflare Tunnel (cloudflared container) receives request
4. Request forwarded to Caddy reverse proxy (internal network)
5. Caddy routes plex.yourdomain.com → http://plex:32400
6. Plex container serves content
7. Response flows back through same encrypted path
```

**Security**: No ports exposed on router. All traffic encrypted through Cloudflare Tunnel.

### Data Flow: Natural Language Automation

```
User: "Download Inception" (via Telegram)
  ↓
Telegram Bot container receives message
  ↓
Validates user ID against whitelist
  ↓
Forwards to MCP Server container
  ↓
MCP Server calls Claude API with:
  - User message
  - Available tools (Docker control, qBittorrent API)
  - System context
  ↓
Claude AI interprets intent:
  "User wants to download a movie called Inception"
  ↓
Claude returns tool calls:
  1. Search qBittorrent for "Inception"
  2. Add torrent to queue
  ↓
MCP Server executes:
  - qBittorrent Web API: Add torrent
  ↓
qBittorrent downloads to /downloads
  ↓
On completion: webhook → MCP Server
  ↓
MCP Server triggers:
  - Plex API: Scan library for new content
  ↓
MCP Server → Telegram Bot: "Inception ready to watch"
  ↓
User receives notification with link to Plex
```

---

## Technology Decisions Explained

### Why Caddy Instead of Apache/Nginx?

**Caddy Advantages:**
- Automatic HTTPS with Let's Encrypt (zero config)
- Modern, simpler syntax (Caddyfile vs Apache configs)
- Built-in reverse proxy features
- Hot reload without downtime
- Better documentation for modern use cases

**Trade-off:** Less mature ecosystem, fewer advanced modules

**Decision:** Simplicity and automatic HTTPS outweigh Apache's maturity for this use case

**Reference:** https://caddyserver.com/docs/

### Why Cloudflare Tunnel Instead of Port Forwarding?

**Security Benefits:**
- Zero exposed ports on home router
- Home IP address hidden from public
- Automatic DDoS protection (Cloudflare infrastructure)
- Encrypted tunnel (TLS 1.3)
- No need to configure router firewall

**Operational Benefits:**
- Works behind CGNAT (Carrier-Grade NAT)
- Automatic SSL certificates
- Easy subdomain routing
- Free tier available

**Trade-off:** Dependency on Cloudflare service

**Decision:** Security and ease of use justify the dependency

**Reference:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

### Why Docker Instead of VMs or Bare Metal?

**Resource Efficiency:**
- Lower overhead than VMs (no guest OS)
- Faster startup times
- Better resource utilization

**Development Experience:**
- Infrastructure as Code (docker-compose.yml)
- Easy to version control
- Reproducible environments
- Simple rollback (image tags)

**Isolation:**
- Better than processes, lighter than VMs
- Network isolation between services
- Resource limits per container

**Trade-off:** Slightly less isolation than VMs

**Decision:** Perfect balance of efficiency, ease of use, and isolation for home server

**Reference:** https://docs.docker.com/get-started/

### Why MCP Server Instead of Traditional Scripts?

**Natural Language Interface:**
- No need to remember exact commands
- More intuitive for non-technical users (future girlfriend access)
- Flexible input parsing

**AI-Powered Decision Making:**
- Claude interprets intent
- Handles variations in phrasing
- Can ask clarifying questions
- Learns from context

**Extensibility:**
- New capabilities = new MCP tools
- Claude automatically learns new features
- No rigid command structure

**Trade-off:** Requires API calls, adds latency

**Decision:** User experience and extensibility justify the complexity

**Reference:** https://modelcontextprotocol.io/

---

## Security Architecture In-Depth

### Defense in Depth Strategy

**Layer 1: Network (Perimeter)**
- No exposed ports on home router
- All traffic through Cloudflare Tunnel (encrypted)
- Home IP address hidden
- Cloudflare's DDoS protection

**Layer 2: Application Gateway**
- Caddy reverse proxy (single entry point)
- Optional Cloudflare Access policies
- Rate limiting (future implementation)
- Request logging and monitoring

**Layer 3: Service Authentication**
- Plex: User accounts with passwords
- qBittorrent: Username/password auth
- Minecraft: Mojang online mode authentication

**Layer 4: Container Isolation**
- Docker networks isolate services
- Non-root users (PUID/PGID 1000)
- Read-only root filesystems (where possible)
- Resource limits prevent DoS

**Layer 5: Automation Security**
- Telegram: User ID whitelist (not just username)
- MCP Server: API key authentication
- Docker API: Unix socket (local only, not TCP)
- Audit logging of all automation actions

### Secrets Management

**Current Approach:**
```
/home/server/.env (NOT in git)
├── CLOUDFLARE_TOKEN
├── TELEGRAM_BOT_TOKEN
├── TELEGRAM_ALLOWED_USERS=123456789,987654321
├── PLEX_CLAIM_TOKEN
├── QBITTORRENT_PASSWORD
└── ANTHROPIC_API_KEY
```

**Git Repository:**
```
.env.example (template, no real values)
```

**Docker Compose References:**
```yaml
environment:
  - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
```

**Future Enhancement:** HashiCorp Vault or Docker Secrets for more robust management

---

## Network Architecture Deep Dive

### Internal Docker Network Topology

```
┌─────────────────────────────────────────────────────────┐
│           Docker Bridge Network: server-net             │
│                     Subnet: 172.20.0.0/16               │
│                                                          │
│  ┌──────────────┐                                       │
│  │   Caddy      │ (172.20.0.2) - Reverse Proxy          │
│  └──────┬───────┘                                       │
│         │                                                │
│         ├────────┐                                       │
│         │        │                                       │
│  ┌──────▼──┐  ┌─▼────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Plex   │  │qBittorrent│ │Minecraft │  │   MCP   │ │
│  │(.10)    │  │  (.11)    │  │ (.20-29) │  │ Server  │ │
│  └─────────┘  └───────────┘  └──────────┘  │  (.30)  │ │
│                                              └────┬────┘ │
│                                                   │      │
│                                          ┌────────▼────┐ │
│                                          │  Telegram   │ │
│                                          │  Bot (.31)  │ │
│                                          └─────────────┘ │
│                                                          │
│  ┌──────────────┐                                       │
│  │ Cloudflared  │ (172.20.0.40) - Tunnel Client         │
│  └──────────────┘                                       │
└─────────────────────────────────────────────────────────┘
```

### Service Communication Matrix

| From | To | Port | Protocol | Purpose |
|------|-----|------|----------|---------|
| Cloudflared | Caddy | 80/443 | HTTP/S | External traffic |
| Caddy | Plex | 32400 | HTTP | Media requests |
| Caddy | qBittorrent | 8080 | HTTP | Web UI |
| Caddy | Minecraft | 25565 | TCP | Game traffic |
| Telegram Bot | MCP Server | 8000 | HTTP | Command forwarding |
| MCP Server | Docker API | Unix socket | - | Container control |
| MCP Server | qBittorrent | 8080 | HTTP | Torrent management |
| MCP Server | Plex | 32400 | HTTP | Library scanning |

**Note:** No service exposed to host network. All isolated within Docker network.

---

## Service Specifications Deep Dive

### Plex Media Server

**Image:** `linuxserver/plex:latest`

**Why linuxserver.io images:**
- Consistent PUID/PGID support
- Excellent documentation
- Regular updates
- Community-maintained
- Cross-platform (AMD64/ARM64)

**Volume Strategy:**
```
/config → plex_config (named volume)
  - Metadata database
  - Transcoding settings
  - User preferences

/media → /mnt/media (bind mount)
  - Movies
  - TV Shows
  - Music

/transcode → tmpfs (RAM disk, optional)
  - Temporary transcoding files
  - Faster, reduces SSD wear
```

**Resource Tuning:**
- **CPU:** 4 cores for transcoding
- **Memory:** 4GB (more if many users)
- **GPU:** Optional hardware transcoding (Intel Quick Sync)

**Integration Points:**
- qBittorrent download complete → Plex library scan
- Telegram notifications for new content
- MCP Server library queries

### qBittorrent

**Image:** `linuxserver/qbittorrent:latest`

**Configuration Highlights:**
```
Downloads location: /downloads/complete
Incomplete location: /downloads/incomplete
Watch folder: /downloads/watch (auto-add .torrent files)
```

**API Integration:**
- MCP Server uses Web API for torrent management
- Webhook on download complete (via script)
- Automatic category assignment

**Optional Enhancement:** Gluetun container for VPN routing

```yaml
network_mode: "service:gluetun"
```

**Privacy Note:** If using VPN, all qBittorrent traffic routed through VPN

### Minecraft Server (Scalable Architecture)

**Image:** `itzg/minecraft-server:latest`

**Multi-Instance Support:**

```yaml
minecraft-survival:
  image: itzg/minecraft-server
  environment:
    TYPE: PAPER
    VERSION: LATEST
    MEMORY: 2G
  volumes:
    - minecraft_survival:/data

minecraft-creative:
  image: itzg/minecraft-server
  environment:
    TYPE: PAPER
    VERSION: LATEST
    MEMORY: 2G
  volumes:
    - minecraft_creative:/data
```

**Subdomain Routing:**
```
survival.yourdomain.com → minecraft-survival:25565
creative.yourdomain.com → minecraft-creative:25565
```

**Automation Capability:**
- Natural language: "Create new Minecraft server for SkyBlock"
- MCP Server generates docker-compose entry
- Auto-configures Caddy routing
- Returns connection info

---

## Automation Layer Architecture

### MCP Server Implementation

**Framework:** FastAPI + MCP Protocol

**Core Structure:**
```python
# main.py
from fastapi import FastAPI
from anthropic import Anthropic
import docker

app = FastAPI()
claude_client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
docker_client = docker.from_env()

@app.post("/command")
async def process_command(command: str):
    # Send command to Claude with available tools
    # Claude returns tool calls
    # Execute tool calls
    # Return results
```

**MCP Tools Implemented:**

```python
tools = [
    {
        "name": "docker_control",
        "description": "Start, stop, or restart Docker containers",
        "input_schema": {
            "type": "object",
            "properties": {
                "action": {"type": "string", "enum": ["start", "stop", "restart"]},
                "container": {"type": "string"}
            }
        }
    },
    {
        "name": "download_manager",
        "description": "Manage downloads via qBittorrent",
        "input_schema": {
            "type": "object",
            "properties": {
                "action": {"type": "string"},
                "query": {"type": "string"}
            }
        }
    },
    # ... more tools
]
```

**Claude Integration:**
```python
response = claude_client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    tools=mcp_tools,
    messages=[
        {"role": "user", "content": user_command}
    ]
)

# Process tool calls from Claude
for block in response.content:
    if block.type == "tool_use":
        result = execute_tool(block.name, block.input)
```

### Telegram Bot Integration

**Architecture:** Webhook-based (not polling)

**Why webhooks:**
- Lower latency
- More efficient (no constant polling)
- Scales better
- Real-time responses

**Security Implementation:**
```python
ALLOWED_USERS = [int(id) for id in os.getenv("TELEGRAM_ALLOWED_USERS").split(",")]

async def message_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id

    if user_id not in ALLOWED_USERS:
        await update.message.reply_text("⛔ Unauthorized")
        return

    # Process command
```

**User Experience Flow:**
```
User: "Download Inception"
Bot: 🔍 Searching for Inception...
Bot: ✅ Found torrent, starting download
Bot: 📊 Progress: 45% (5 min remaining)
Bot: ✅ Download complete!
Bot: 📺 Added to Plex library
Bot: 🎬 Ready to watch at https://plex.yourdomain.com
```

---

## Extensibility & Future Enhancements

### Adding New Services

**Process:**
1. Add to `docker-compose.yml`
2. Create subdomain in Cloudflare DNS
3. Add route to Caddyfile
4. (Optional) Create MCP tools for automation
5. Deploy with `docker-compose up -d`

**Example: Adding Sonarr (TV Show Automation)**

```yaml
# docker-compose.yml
sonarr:
  image: linuxserver/sonarr
  environment:
    - PUID=1000
    - PGID=1000
  volumes:
    - sonarr_config:/config
    - /media/tv:/tv
    - /downloads:/downloads
  networks:
    - server-net
```

```
# Caddyfile
sonarr.yourdomain.com {
    reverse_proxy sonarr:8989
}
```

Natural language integration:
```python
# New MCP tool
{
    "name": "tv_show_manager",
    "description": "Add TV shows to Sonarr for automated downloading"
}
```

**Result:** "Add Breaking Bad to Sonarr" → automatically monitors and downloads

### Planned Enhancements

**Phase 3: Monitoring & Optimization**
- Grafana + Prometheus for metrics
- Alerting (disk space, CPU spikes)
- Performance optimization
- Automated backups

**Phase 4: Advanced Automation**
- Multi-user support (girlfriend access)
- Voice control integration (Home Assistant?)
- Automated media requests from Plex
- Smart scheduling (downloads during off-peak hours)

**Phase 5: Home Integration**
- Smart home device control
- Presence detection
- Automated routines
- Energy monitoring

---

## Development & Maintenance

### Project Structure

```
home-server/
├── .claude/                  # Claude Code documentation
│   ├── architecture.md
│   ├── technical_specs.md
│   ├── api_documentation.md
│   └── commands/
│       ├── explain.md
│       └── explain_deep.md
├── docker-compose.yml        # Service orchestration
├── .env.example              # Template for secrets
├── .env                      # Real secrets (NOT in git)
├── caddy/
│   └── Caddyfile            # Reverse proxy config
├── mcp-server/
│   ├── main.py              # FastAPI server
│   ├── requirements.txt
│   ├── tools/               # MCP tool implementations
│   └── Dockerfile
├── telegram-bot/
│   ├── bot.py
│   ├── requirements.txt
│   └── Dockerfile
└── README.md
```

### Maintenance Procedures

**Weekly:**
- Check Docker container health: `docker ps`
- Review disk usage: `df -h`
- Check logs for errors: `docker-compose logs --tail=100`

**Monthly:**
- Update Docker images: `docker-compose pull && docker-compose up -d`
- Backup configurations: `cp docker-compose.yml /backup/`
- Backup Docker volumes: (see technical_specs.md)

**Quarterly:**
- Review security settings
- Update OS packages: `sudo apt update && sudo apt upgrade`
- Review and optimize resource allocation

### Troubleshooting Guide

**Service won't start:**
```bash
docker logs <container_name>  # Check logs
docker inspect <container_name>  # Inspect configuration
```

**Can't access via subdomain:**
```bash
docker logs cloudflared  # Check tunnel status
docker logs caddy  # Check reverse proxy routing
```

**Automation not working:**
```bash
docker logs mcp-server  # Check MCP Server logs
docker logs telegram-bot  # Check bot logs
```

---

## Learning Resources

### Core Technologies

**Docker:**
- [Official Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

**Caddy:**
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddyfile Concepts](https://caddyserver.com/docs/caddyfile/concepts)

**Cloudflare Tunnel:**
- [Cloudflare Tunnel Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

**MCP Protocol:**
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Anthropic MCP Documentation](https://docs.anthropic.com/en/docs/mcp)

**Telegram Bots:**
- [python-telegram-bot Documentation](https://docs.python-telegram-bot.org/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

---

## Project Success Metrics

### Technical Milestones
- ✅ Hardware setup complete
- ✅ Ubuntu Server installed
- ✅ Docker configured
- ⏳ Core services deployed (Plex, qBittorrent, Minecraft)
- ⏳ Cloudflare Tunnel configured
- ⏳ Caddy reverse proxy working
- ⏳ MCP Server implemented
- ⏳ Telegram Bot connected
- ⏳ Natural language automation working

### Learning Objectives
- ✅ Understand containerization concepts
- ⏳ Understand DNS and reverse proxies
- ⏳ Implement zero-trust networking
- ⏳ Build RESTful API
- ⏳ Integrate AI into infrastructure
- ⏳ Create maintainable Infrastructure as Code

### Operational Goals
- System uptime > 99%
- Easy to add new services (< 30 min)
- Natural language commands work reliably
- Can explain and troubleshoot any component
- Fully documented and reproducible

---

## Conclusion

This project is a **comprehensive learning platform** that combines:
- Modern DevOps practices (Docker, IaC, monitoring)
- Security best practices (zero-trust, secrets management)
- AI integration (Claude API, natural language processing)
- System architecture (networking, reverse proxy, service orchestration)

The goal isn't just to have working services, but to **deeply understand** every layer of the stack, enabling future expansion and confident system administration.

---

## Quick Reference: All Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project instructions and philosophy
- **[.claude/architecture.md](.claude/architecture.md)** - System architecture
- **[.claude/technical_specs.md](.claude/technical_specs.md)** - Technical specifications
- **[.claude/api_documentation.md](.claude/api_documentation.md)** - API references
- **[.claude/code_examples.md](.claude/code_examples.md)** - Code samples

**Custom Commands:**
- `/explain` - This overview
- `/explain_deep` - This comprehensive guide
