# Technical Specifications

## Hardware Requirements

### Mini PC Server Specifications

**Minimum Requirements:**
- **CPU**: Intel i3 (8th gen+) or AMD Ryzen 3 (3000 series+)
- **RAM**: 16GB DDR4
- **Storage**: 
  - 256GB NVMe SSD (OS + Docker)
  - Optional: 1TB+ HDD/SSD for media
- **Network**: Gigabit Ethernet (WiFi not recommended)
- **Power**: Low idle power consumption (<15W)

**Recommended Specifications:**
- **CPU**: Intel i5 (10th gen+) or AMD Ryzen 5 (5000 series+)
- **RAM**: 32GB DDR4
- **Storage**:
  - 500GB NVMe SSD (OS + Docker + overhead)
  - 2-4TB SSD/HDD for media storage
- **Network**: Gigabit Ethernet
- **Power**: <20W idle

**Recommended Models (2024-2025):**
- Beelink SER5 Max (AMD Ryzen 7 5800H)
- Intel NUC 11/12 series
- Minisforum UM773 Lite
- ASUS PN51 or PN52

### Storage Layout

```
/dev/nvme0n1 (500GB SSD - System)
├── /dev/nvme0n1p1 - EFI (512MB)
├── /dev/nvme0n1p2 - / (100GB) - OS
└── /dev/nvme0n1p3 - /var/lib/docker (400GB) - Containers

/dev/sda1 (2TB HDD - Optional Media)
└── /media (2TB) - Plex media storage
```

## Software Stack

### Operating System

**Distribution**: Ubuntu Server 22.04 LTS (or latest LTS)

**Why Ubuntu Server:**
- Long-term support (5 years)
- Excellent Docker support
- Large community
- Well-documented
- Stable and reliable

**Installation Type**: Minimal installation (no desktop environment)

### Container Runtime

**Docker Engine**: Version 24.x or later
**Docker Compose**: Version 2.x (plugin version, not standalone)

**Installation Method**: Official Docker repository (not snap)

```bash
# Docker Engine CE (Community Edition)
# Docker Compose Plugin
# Docker CLI
```

### Reverse Proxy

**Caddy**: Version 2.7.x or later

**Key Features Used:**
- Automatic HTTPS
- Reverse proxy
- File server
- Template engine
- API endpoints

**Configuration Format**: Caddyfile (not JSON)

### Tunnel Client

**Cloudflared**: Latest version from Cloudflare

**Protocol**: HTTP/2 and QUIC support

**Features Used:**
- Named tunnels
- Configuration file support
- Auto-restart
- Health checks

## Network Specifications

### Internal Docker Networks

**Network Type**: Multiple isolated bridge networks
**Current Networks:**
- `proxy` - Reverse proxy and external-facing services
- `auth` - Authentication services (Authelia, PostgreSQL, Redis)
- `monitoring` - Logging stack (Loki, Promtail, Grafana)
- `web` - Web services and portal
- `compose_default` - Default network for services

**Network Isolation:**
- Services only join networks they need
- Auth stack isolated from media services
- Monitoring stack can observe all containers via Docker socket

### Port Mapping (Internal Only)

| Service | Internal Port | Protocol | Purpose |
|---------|--------------|----------|---------|
| Caddy | 80, 443 | HTTP/HTTPS | Reverse proxy |
| Jellyfin | 8096 | HTTP | Media streaming |
| Jellyseerr | 5055 | HTTP | Media requests |
| Prowlarr | 9696 | HTTP | Indexer manager |
| Radarr | 7878 | HTTP | Movie management |
| Sonarr | 8989 | HTTP | TV show management |
| qBittorrent | 8080 | HTTP | Web UI |
| qBittorrent | 6881 | TCP/UDP | Torrent traffic |
| Authelia | 9091 | HTTP | SSO authentication |
| PostgreSQL | 5432 | TCP | Database |
| Redis | 6379 | TCP | Session storage |
| Loki | 3100 | HTTP | Log aggregation |
| Promtail | 9080 | HTTP | Log collection |
| Grafana | 3000 | HTTP | Monitoring UI |
| Portal | 80 | HTTP | Management portal |
| Cloudflared | - | - | Tunnel only |

**Note**: NO ports exposed on host machine or router

### DNS Configuration

**Domain Registrar**: Any (Namecheap, GoDaddy, etc.)
**DNS Provider**: Cloudflare (mandatory for tunnel)

**DNS Records:**
```
Type: CNAME
Name: auth
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: streaming
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: requests
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: prowlarr
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: radarr
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: sonarr
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: torrent
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: monitor
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)

Type: CNAME
Name: portal
Target: <tunnel-id>.cfargotunnel.com
Proxy: Yes (orange cloud)
```

## Service Specifications

### Current Service Stack (17 Containers)

**Authentication Layer:**
- Authelia - SSO authentication service
- PostgreSQL - Auth database
- Redis - Session storage

**Media Stack:**
- Jellyfin - Media streaming server
- Jellyseerr - Media request management
- Prowlarr - Indexer manager
- Radarr - Movie management
- Sonarr - TV show management
- qBittorrent - Torrent client

**Infrastructure:**
- Caddy - Reverse proxy
- Cloudflared - Cloudflare Tunnel client
- Watchtower - Auto-updates for containers

**Monitoring Stack:**
- Loki - Log aggregation
- Promtail - Log collector
- Grafana - Visualization

**Web Services:**
- Portal - Management portal (Angular)
- hello-world - Test service

---

### Jellyfin Media Server

**Docker Image**: `lscr.io/linuxserver/jellyfin:latest`
**Version**: Latest stable
**Architecture**: AMD64/ARM64

**Environment Variables:**
```
PUID=1000
PGID=1000
TZ=America/New_York
```

**Volumes:**
```
/config - Jellyfin configuration and metadata
/data/tvshows - TV shows
/data/movies - Movie files
/data/cache - Transcoding cache
```

**Resource Limits:**
```
CPU: 4 cores
Memory: 4GB
Storage: Unlimited (media)
```

**Features:**
- Hardware acceleration support
- DLNA server
- Live TV & DVR
- Mobile sync

---

### Plex Media Server (Legacy - Not Currently Used)

**Docker Image**: `linuxserver/plex:latest`
**Version**: Latest stable
**Architecture**: AMD64/ARM64

**Environment Variables:**
```
PUID=1000
PGID=1000
VERSION=docker
TZ=Europe/Madrid
PLEX_CLAIM=<claim-token>
```

**Volumes:**
```
/config - Plex configuration and metadata
/media - Media files (movies, TV shows)
/transcode - Temporary transcoding files
```

**Resource Limits:**
```
CPU: 4 cores
Memory: 4GB
Storage: Unlimited (media)
```

### qBittorrent

**Docker Image**: `linuxserver/qbittorrent:latest`
**Version**: 4.6.x or later
**Architecture**: AMD64/ARM64

**Environment Variables:**
```
PUID=1000
PGID=1000
TZ=Europe/Madrid
WEBUI_PORT=8080
```

**Volumes:**
```
/config - qBittorrent settings
/downloads - Download destination
```

**Resource Limits:**
```
CPU: 2 cores
Memory: 2GB
Storage: Unlimited (downloads)
```

**Network Configuration:**
```
Network mode: Bridge
VPN: Optional (via gluetun container)
```

### Minecraft Server

**Docker Image**: `itzg/minecraft-server:latest`
**Version**: Java Edition, latest release
**Architecture**: AMD64/ARM64

**Environment Variables:**
```
EULA=TRUE
TYPE=PAPER (or VANILLA, FORGE, etc.)
VERSION=LATEST
MEMORY=2G
DIFFICULTY=normal
MAX_PLAYERS=10
ONLINE_MODE=TRUE
```

**Volumes:**
```
/data - World files and server config
```

**Resource Limits:**
```
CPU: 2 cores per instance
Memory: 2-4GB per instance (configurable)
Storage: 10GB per world (average)
```

**Scalability**: Support for multiple instances via docker-compose

## Automation Layer Specifications

### MCP Server

**Framework**: FastAPI (Python 3.11+)
**Version**: Custom implementation
**Architecture**: REST API + MCP Protocol

**Core Dependencies:**
```python
fastapi>=0.104.0
uvicorn>=0.24.0
anthropic>=0.7.0
docker>=6.1.0
python-telegram-bot>=20.0
pydantic>=2.4.0
```

**API Endpoints:**
```
POST /command - Process natural language command
GET /status - Service status
POST /docker/start - Start container
POST /docker/stop - Stop container
POST /docker/restart - Restart container
GET /docker/logs - Get container logs
```

**MCP Tools Implemented:**
```python
- docker_control (start, stop, restart)
- container_logs (view logs)
- service_status (check health)
- download_manager (qBittorrent control)
- minecraft_manager (create, configure servers)
```

### Telegram Bot

**Library**: python-telegram-bot (v20+)
**Architecture**: Webhook-based (not polling)

**Command Structure:**
```
/start - Initialize bot
/status - Show all service status
/help - Command reference
[natural language] - Send to MCP Server
```

**Authentication:**
```python
ALLOWED_USER_IDS = [123456789]  # Whitelist
```

**Features:**
- Natural language processing
- Inline keyboards for actions
- Status notifications
- Webhook integration
- Error handling

### Claude AI Integration

**API**: Anthropic Claude API
**Model**: Claude Sonnet 4 or Sonnet 4.5
**Model String**: `claude-sonnet-4-20250514`

**Request Structure:**
```python
{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 1024,
    "tools": [MCP_TOOLS],
    "messages": [
        {"role": "user", "content": "Download Inception"}
    ]
}
```

**Token Budget**: ~1000 tokens per command (average)

## Security Specifications

### SSL/TLS Configuration

**Provider**: Cloudflare + Let's Encrypt (via Caddy)
**Protocol**: TLS 1.3
**Cipher Suites**: Modern configuration (AEAD only)

### Authentication Layers

1. **Cloudflare Access** (Optional)
   - IP whitelisting
   - Email authentication
   - One-time PIN

2. **Service Authentication**
   - Plex: User accounts
   - qBittorrent: Username/password
   - Minecraft: Online mode (Mojang auth)

3. **Automation Authentication**
   - Telegram: User ID whitelist
   - MCP Server: API key
   - Docker API: Unix socket (local only)

### Container Security

**Run as non-root**: All containers use PUID/PGID 1000
**Read-only root**: Where applicable
**No privileged mode**: Unless absolutely necessary
**Network isolation**: Services can't access each other unless needed

## Data Specifications

### Volume Management

**Named Volumes** (preferred for config):
```
caddy_config
caddy_data
plex_config
qbittorrent_config
minecraft_data
```

**Bind Mounts** (for media):
```
/media → /path/on/host/media
/downloads → /path/on/host/downloads
```

### Backup Strategy

**What to Backup:**
- Docker Compose files
- Caddy configuration
- Service configurations (via volumes)
- Media files (optional, if space permits)

**Backup Schedule:**
- Configurations: Daily
- Media: Weekly (optional)
- Full system: Monthly

**Backup Method:**
```bash
# Volume backup
docker run --rm -v <volume>:/data -v /backup:/backup \
  alpine tar czf /backup/<name>.tar.gz /data

# Configuration backup
cp docker-compose.yml /backup/
cp -r caddy/ /backup/caddy/
```

## Performance Specifications

### Expected Resource Usage

**Idle State:**
- CPU: 5-10% (monitoring overhead)
- RAM: 2-4GB
- Disk I/O: Minimal
- Network: <1 Mbps

**Active Usage (Streaming + Download):**
- CPU: 20-40% (with transcoding: 60-80%)
- RAM: 6-10GB
- Disk I/O: 50-100 MB/s (write, downloads)
- Network: 5-50 Mbps (streaming quality dependent)

**Minecraft Server (Per Instance):**
- CPU: 10-30% (player dependent)
- RAM: 2-4GB (configurable)
- Disk I/O: Minimal (except world saves)
- Network: 1-5 Mbps

### Scaling Thresholds

**When to Upgrade Hardware:**
- CPU: >80% sustained usage
- RAM: >90% usage with swap
- Storage: <10% free space
- Network: Approaching ISP bandwidth limit

## API Specifications

### Docker API

**Version**: 1.43+
**Access**: Unix socket (`/var/run/docker.sock`)
**Methods Used**:
- Container start/stop/restart
- Container logs
- Container inspection
- Compose operations

### qBittorrent Web API

**Version**: 4.6.x
**Authentication**: Cookie-based
**Endpoints Used**:
```
POST /api/v2/auth/login
GET /api/v2/torrents/info
POST /api/v2/torrents/add
POST /api/v2/torrents/delete
```

### Plex API

**Version**: Plex Media Server API
**Authentication**: X-Plex-Token
**Endpoints Used**:
```
GET /library/sections (list libraries)
GET /library/sections/{id}/refresh (scan library)
GET /status/sessions (active streams)
```

### Anthropic Claude API

**Version**: 2023-06-01
**Authentication**: Bearer token (API key)
**Rate Limits**: 
- Tier 1: 50 requests/minute
- Tier 2: 1000 requests/minute

## Development Environment

### Local Development Setup

**OS**: Linux/macOS/Windows (with WSL2)
**IDE**: VS Code with extensions:
- Docker
- Python
- YAML
- Markdown

**Testing Tools**:
- Docker Compose (local testing)
- Postman/cURL (API testing)
- pytest (MCP Server testing)

### Version Control

**Repository Structure**:
```
project-root/
├── docker-compose.yml
├── .env.example
├── caddy/
│   └── Caddyfile
├── mcp-server/
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── telegram-bot/
│   ├── bot.py
│   ├── requirements.txt
│   └── Dockerfile
└── README.md
```

**Git Ignore**:
- `.env` (secrets)
- `*.log` (logs)
- `data/` (persistent data)
- `config/` (service configs with passwords)

## Monitoring & Metrics

### Health Check Configuration

**Docker Health Checks**:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:80/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Metrics to Track

**System Metrics**:
- CPU usage per container
- Memory usage per container
- Disk I/O per container
- Network traffic per container

**Application Metrics**:
- Plex: Active streams, transcoding
- qBittorrent: Download/upload speed, queue
- Minecraft: Player count, TPS (ticks per second)
- MCP Server: Command success rate, response time

## Compliance & Best Practices

### Docker Best Practices

- Use official or verified images
- Pin image versions (avoid `latest` in production)
- Multi-stage builds for custom images
- Minimal base images (Alpine where possible)
- Health checks for all services
- Resource limits for all containers

### Security Best Practices

- Secrets in environment variables (not in code)
- Regular security updates
- Principle of least privilege
- Network segmentation
- Regular backups
- Audit logging

### Code Best Practices

- PEP 8 (Python style guide)
- Type hints for Python code
- Comprehensive error handling
- Logging at appropriate levels
- Documentation for all functions
- Unit tests for critical components