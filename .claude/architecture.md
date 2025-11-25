# Home Server Architecture Documentation

## System Overview

This document describes the complete architecture of the home server automation project, including all components, their interactions, and design decisions.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (443)
                         │
                    ┌────▼────┐
                    │Cloudflare│
                    │  DNS     │
                    └────┬────┘
                         │
                         │ Cloudflare Tunnel
                         │ (Encrypted, No Exposed Ports)
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    HOME NETWORK                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              MINI PC SERVER                          │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │         Cloudflared (Tunnel Client)          │   │  │
│  │  └─────────────────┬────────────────────────────┘   │  │
│  │                    │                                 │  │
│  │  ┌─────────────────▼────────────────────────────┐   │  │
│  │  │       Caddy (Reverse Proxy)                  │   │  │
│  │  │  - Subdomain routing                         │   │  │
│  │  │  - Internal SSL/TLS                          │   │  │
│  │  │  - Load balancing                            │   │  │
│  │  └─────┬──────────┬──────────┬─────────┬────────┘   │  │
│  │        │          │          │         │            │  │
│  │  ┌─────▼──┐  ┌───▼───┐  ┌──▼────┐  ┌─▼──────┐    │  │
│  │  │  Plex  │  │qBittor│  │Minecraft│ │  MCP   │    │  │
│  │  │        │  │rent   │  │ Server  │ │ Server │    │  │
│  │  └────────┘  └───────┘  └─────────┘ └────┬───┘    │  │
│  │                                            │        │  │
│  │                                      ┌─────▼─────┐ │  │
│  │                                      │ Telegram  │ │  │
│  │                                      │    Bot    │ │  │
│  │                                      └───────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Cloudflare Layer

**Purpose**: DNS management and secure tunnel to home server

**Components:**
- Cloudflare DNS: Manages domain and subdomains
- Cloudflare Tunnel: Encrypted tunnel without port forwarding
- SSL/TLS Certificates: Automatic certificate management

**Subdomains:**
- `plex.yourdomain.com` → Plex Media Server
- `torrents.yourdomain.com` → qBittorrent Web UI
- `minecraft.yourdomain.com` → Minecraft Server
- `automation.yourdomain.com` → MCP Server API (optional)

**Why Cloudflare Tunnel:**
- No exposed ports (security)
- Automatic DDoS protection
- Free tier available
- Hides home IP address
- Built-in SSL/TLS

### 2. Reverse Proxy (Caddy)

**Purpose**: Internal routing and traffic management

**Responsibilities:**
- Route subdomain requests to correct containers
- Handle internal SSL/TLS
- Provide unified logging
- Enable future load balancing

**Configuration Location**: `/home/server/caddy/Caddyfile`

**Key Features:**
- Automatic HTTPS with Let's Encrypt
- Simple configuration syntax
- Hot reload on config changes
- Built-in health checks

**Example Routing:**
```
plex.yourdomain.com → http://plex:32400
torrents.yourdomain.com → http://qbittorrent:8080
minecraft.yourdomain.com → tcp://minecraft:25565
```

### 3. Docker Environment

**Purpose**: Container orchestration and service isolation

**Components:**
- Docker Engine: Container runtime
- Docker Compose: Multi-container orchestration
- Docker Networks: Service communication
- Docker Volumes: Persistent data storage

**Network Architecture:**
```
┌─────────────────────────────────────────┐
│      Docker Network: server-net         │
│  ┌────────┐  ┌────────┐  ┌──────────┐  │
│  │ Caddy  │  │  Plex  │  │qBittorrent│ │
│  └───┬────┘  └───┬────┘  └─────┬─────┘  │
│      │           │              │        │
│      └───────────┴──────────────┘        │
│           Can communicate internally     │
└─────────────────────────────────────────┘
```

### 4. Core Services

#### Plex Media Server
- **Purpose**: Stream media to devices
- **Port**: 32400 (internal only)
- **Volumes**: `/media` (media files), `/config` (settings)
- **Integration**: Monitors qBittorrent downloads folder

#### qBittorrent
- **Purpose**: Download manager
- **Port**: 8080 (web UI, internal only)
- **Volumes**: `/downloads`, `/config`
- **Integration**: Provides download complete webhooks

#### Minecraft Server
- **Purpose**: Game server (expandable to multiple instances)
- **Port**: 25565 (internal only)
- **Volumes**: `/data` (world files), `/mods`
- **Features**: Multiple server support via Docker Compose scaling

### 5. Automation Layer

#### MCP Server
- **Purpose**: Natural language command processing
- **Technology**: Python + FastAPI + Claude API
- **Responsibilities**:
  - Parse natural language commands
  - Execute Docker operations
  - Manage service lifecycle
  - Report status and results

**Example Capabilities:**
- Start/stop/restart containers
- Create new service instances
- Monitor system resources
- Download management
- Configuration updates

#### Telegram Bot
- **Purpose**: User interface for automation
- **Technology**: Python + python-telegram-bot
- **Features**:
  - Natural language input
  - Status notifications
  - Webhook receivers
  - Authentication (user whitelist)

**Command Flow:**
```
User: "Download Inception"
  ↓
Telegram Bot receives message
  ↓
Sends to MCP Server
  ↓
MCP Server asks Claude AI to interpret
  ↓
Claude generates action plan
  ↓
MCP Server executes via Docker API
  ↓
qBittorrent starts download
  ↓
Webhook fires on completion
  ↓
Telegram Bot notifies user
```

## Data Flow Examples

### Example 1: External Access to Plex
```
1. User visits plex.yourdomain.com
2. DNS resolves to Cloudflare
3. Cloudflare Tunnel routes to cloudflared container
4. cloudflared forwards to Caddy
5. Caddy routes plex.yourdomain.com → plex:32400
6. Plex serves content
7. Response flows back through same path
```

### Example 2: Download and Stream Movie
```
1. User: "Download The Matrix" (Telegram)
2. Telegram Bot → MCP Server
3. MCP Server → Claude AI (interpret command)
4. Claude returns: Search qBittorrent, add torrent
5. MCP Server → qBittorrent API (add torrent)
6. qBittorrent downloads to /downloads
7. On complete: webhook → MCP Server
8. MCP Server → Plex API (scan library)
9. MCP Server → Telegram Bot (notify user)
10. User can now stream via plex.yourdomain.com
```

### Example 3: Create New Minecraft Server
```
1. User: "Create SurvivalWorld Minecraft server" (Telegram)
2. Telegram Bot → MCP Server
3. MCP Server → Claude AI (interpret + generate config)
4. Claude returns: docker-compose template
5. MCP Server creates new service definition
6. Docker Compose starts new container
7. MCP Server updates Caddy config
8. Caddy reloads (survivalworld.yourdomain.com active)
9. MCP Server → Telegram Bot (send connection info)
```

## Security Architecture

### Layers of Security

1. **Network Layer**
   - No exposed ports on home router
   - All traffic through encrypted Cloudflare Tunnel
   - Home IP address hidden

2. **Application Layer**
   - Cloudflare access policies (IP whitelisting optional)
   - Caddy authentication middleware
   - Service-level authentication (Plex, qBittorrent)

3. **Container Layer**
   - Non-root users in containers
   - Read-only root filesystems where possible
   - Network isolation between services
   - Resource limits (CPU, memory)

4. **Automation Layer**
   - Telegram user ID whitelist
   - MCP Server API authentication
   - Rate limiting on commands
   - Audit logging of all actions

### Secrets Management

```
/home/server/.env
├── CLOUDFLARE_TOKEN
├── TELEGRAM_BOT_TOKEN
├── TELEGRAM_ALLOWED_USERS
├── PLEX_CLAIM_TOKEN
├── QBITTORRENT_PASSWORD
└── ANTHROPIC_API_KEY
```

**Never committed to git** - use `.env.example` template instead

## Scalability & Extensibility

### Adding New Services

1. Create service definition in `docker-compose.yml`
2. Add subdomain to Cloudflare DNS
3. Add route to Caddyfile
4. Restart Caddy container
5. (Optional) Add MCP Server tools for automation

### Adding New Automation Commands

1. Define new tool in MCP Server
2. Implement Docker API calls
3. Update Telegram Bot command list
4. Test with natural language variations
5. Document in command reference

### Resource Scaling

- **Horizontal**: Add more service instances (multiple Minecraft servers)
- **Vertical**: Increase container resource limits
- **Storage**: Add volume mounts for new media drives
- **Compute**: Upgrade mini PC hardware as needed

## Monitoring & Maintenance

### Logging Strategy
- Container logs: `docker logs <container>`
- Caddy access logs: `/var/log/caddy/access.log`
- MCP Server logs: `/var/log/mcp-server/`
- Centralized logging: (Future) ELK stack or Loki

### Backup Strategy
- Docker volumes: Automated backup script
- Configurations: Git repository
- Media: (Optional) Separate backup solution
- Database: (If added) Automated dumps

### Health Checks
- Docker health checks in compose file
- Caddy uptime monitoring
- MCP Server heartbeat
- Telegram Bot alive check

## Technology Decisions

### Why Caddy over Apache/Nginx?
- Automatic HTTPS (Let's Encrypt integration)
- Simpler configuration syntax
- Modern architecture
- Built-in reverse proxy features
- Better documentation for this use case

### Why Cloudflare Tunnel over Port Forwarding?
- No exposed ports (security)
- Automatic DDoS protection
- Free SSL certificates
- Hides home IP
- No router configuration needed

### Why Docker over VMs?
- Lighter resource usage
- Faster deployment
- Easier to manage
- Infrastructure as Code
- Better isolation than processes

### Why MCP Server over Traditional Scripts?
- Natural language interface
- Flexible command interpretation
- AI-powered decision making
- Easier to extend
- Better user experience

## Future Enhancements

### Phase 1 (Current)
- Basic service deployment
- Cloudflare Tunnel setup
- Simple Telegram commands

### Phase 2
- Advanced automation workflows
- Multi-instance Minecraft support
- Custom web apps deployment

### Phase 3
- Monitoring dashboard
- Automated backups
- Resource optimization

### Phase 4
- Home automation integration
- Advanced AI workflows
- Multi-user support (with girlfriend)

## References

- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Caddy Documentation: https://caddyserver.com/docs/
- Docker Compose: https://docs.docker.com/compose/
- MCP Protocol: https://modelcontextprotocol.io/
- Telegram Bot API: https://core.telegram.org/bots/api