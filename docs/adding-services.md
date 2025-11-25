# Adding New Services to Your Home Server

This guide explains how to add new Docker services with public HTTPS access through Caddy and Cloudflare Tunnel.

## Table of Contents
1. [Critical Configuration Requirements](#critical-configuration-requirements)
2. [Quick Start Template](#quick-start-template)
3. [Step-by-Step Guide](#step-by-step-guide)
4. [Examples](#examples)
5. [Troubleshooting](#troubleshooting)

---

## Critical Configuration Requirements

⚠️ **MUST-FOLLOW rules learned from troubleshooting sessions:**

### 1. Caddyfile Site Blocks
- **ALWAYS use `https://` prefix** in site block definitions
- Example: `https://subdomain.mykyta-ryasny.dev {` ✅
- NOT: `subdomain.mykyta-ryasny.dev {` ❌
- Use `.Caddyfile` extension (not `.caddy`) for syntax highlighting

### 2. Cloudflare DNS Records
- **Type**: CNAME (never A record for tunnels)
- **Target**: `07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com`
- **Proxy Status**: **MUST be Proxied (orange cloud)** ⚠️
  - This is CRITICAL - "DNS only" (grey cloud) will NOT work
  - When you see grey cloud, click it to turn orange
  - Propagation takes 30-60 seconds after changing to Proxied

### 3. Cloudflare Tunnel Configuration
- Add EVERY subdomain to `config.yml` ingress rules
- Must include `originServerName` matching the hostname
- Order matters - catch-all `http_status:404` must be LAST

### 4. File Organization (After Refactor)
```
/opt/homeserver/
├── docker-compose.yml (includes compose/*.yml)
├── compose/
│   ├── proxy.yml       # Caddy configuration
│   ├── tunnel.yml      # Cloudflare Tunnel
│   ├── web.yml         # Static websites
│   └── media.yml       # Media services
└── services/
    ├── proxy/caddy/
    │   ├── Caddyfile
    │   ├── sites/*.Caddyfile  # Individual service configs
    │   └── certs/
    ├── tunnel/cloudflared/
    │   └── config.yml
    └── media/
        ├── jellyfin/
        ├── qbittorrent/
        └── ...
```

---

## Quick Start Template

### 1. Add Docker Service to `docker-compose.yml`

```yaml
  # Service N: Your New Service
  your-service-name:
    image: service/image:tag
    container_name: your-service-name
    restart: unless-stopped
    # Expose ports only if needed for internal access
    # ports:
    #   - "8080:8080"
    volumes:
      - ./services/your-service-name/config:/config
    networks:
      - web
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
```

### 2. Create Caddy Site Configuration

File: `/opt/homeserver/services/proxy/caddy/sites/your-service-name.Caddyfile`

**IMPORTANT:** Use `.Caddyfile` extension (not `.caddy`) for syntax highlighting support.

```caddy
# ============================================================================
# Your Service Name Configuration
# ============================================================================
# Description: Brief description of what this service does
# Container: your-service-name
# Port: Internal port the container listens on
# ============================================================================

# Main subdomain - MUST include https:// prefix
https://subdomain.mykyta-ryasny.dev {
    # Import Cloudflare Origin Certificate configuration
    import cf_tls

    # Reverse proxy to your service container
    reverse_proxy your-service-name:PORT
}
```

**Critical Notes:**
- **ALWAYS use `https://` prefix** in the site block (e.g., `https://subdomain.mykyta-ryasny.dev`)
- Use `.Caddyfile` extension for better IDE support
- File name should match the service or subdomain name

### 3. Add DNS Record in Cloudflare

1. Go to Cloudflare Dashboard → DNS → Records
2. Add CNAME record:
   - **Type**: CNAME
   - **Name**: subdomain (e.g., `plex`)
   - **Target**: `07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com`
   - **Proxy status**: **Proxied (orange cloud)** ⚠️ CRITICAL!
   - **TTL**: Auto

**⚠️ IMPORTANT:** The proxy status **MUST** be orange cloud (Proxied), NOT grey cloud (DNS only). If you accidentally set it to DNS only, the subdomain will NOT work. Click the cloud icon to toggle to orange/Proxied.

### 4. Update Cloudflare Tunnel Configuration

File: `/opt/homeserver/services/cloudflared/config.yml`

Add your new hostname to the ingress rules:

```yaml
ingress:
  # Existing rules...

  # Your new service
  - hostname: subdomain.mykyta-ryasny.dev
    service: https://caddy:443
    originRequest:
      noTLSVerify: true
      originServerName: subdomain.mykyta-ryasny.dev

  # Keep the 404 catch-all at the end
  - service: http_status:404
```

### 5. Deploy

```bash
# Navigate to project directory
cd /opt/homeserver

# Start the new service
docker compose up -d

# Verify containers are running
docker compose ps

# Check logs if there are issues
docker compose logs your-service-name
docker compose logs caddy
docker compose logs cloudflared
```

---

## Step-by-Step Guide

### Phase 1: Plan Your Service

Before adding a service, decide:

1. **What subdomain?** (e.g., `plex.mykyta-ryasny.dev`)
2. **What Docker image?** Check Docker Hub or LinuxServer.io
3. **What port does it use internally?** (e.g., Plex uses 32400)
4. **What volumes does it need?** (config, data, media, etc.)
5. **Any special environment variables?** (timezone, user IDs, API keys)

### Phase 2: Add to Docker Compose

Edit `/opt/homeserver/docker-compose.yml`:

```yaml
  your-service:
    image: your/image:latest
    container_name: your-service
    restart: unless-stopped
    volumes:
      - ./services/your-service/config:/config
      - ./media:/media  # If it needs access to media files
    networks:
      - web  # IMPORTANT: Must be on the 'web' network to communicate with Caddy
    environment:
      - TZ=Europe/Madrid
```

**Important Notes:**
- Always add `networks: - web` so it can communicate with Caddy
- Don't expose ports with `ports:` unless you need direct access on your LAN
- Use `restart: unless-stopped` for production services
- Store configs in `./services/your-service/` for easy backup

### Phase 3: Create Caddy Configuration

Create file: `/opt/homeserver/services/caddy/sites/your-service.caddy`

**Simple reverse proxy:**
```caddy
https://subdomain.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy your-service:8080
}
```

**With custom headers (for some services like Jellyfin):**
```caddy
https://jellyfin.mykyta-ryasny.dev {
    import cf_tls

    # Custom headers for Jellyfin
    header {
        X-Forwarded-Proto https
    }

    reverse_proxy jellyfin:8096
}
```

**With WebSocket support (for services like Minecraft web consoles):**
```caddy
https://console.mykyta-ryasny.dev {
    import cf_tls

    # Enable WebSocket support
    reverse_proxy minecraft-console:8080 {
        # Preserve WebSocket upgrade headers
        header_up Upgrade {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
    }
}
```

**File permissions:** Make sure the file is readable:
```bash
chmod 644 /opt/homeserver/services/caddy/sites/your-service.caddy
```

### Phase 4: Configure Cloudflare Tunnel

Edit `/opt/homeserver/services/cloudflared/config.yml`:

Add your new ingress rule **BEFORE** the `http_status:404` catch-all:

```yaml
ingress:
  # ... existing rules ...

  - hostname: your-subdomain.mykyta-ryasny.dev
    service: https://caddy:443
    originRequest:
      noTLSVerify: true
      originServerName: your-subdomain.mykyta-ryasny.dev

  # This MUST stay at the end
  - service: http_status:404
```

**Why this configuration?**
- `service: https://caddy:443` - Connect to Caddy via HTTPS
- `noTLSVerify: true` - Don't verify cert (it's a Cloudflare Origin Cert)
- `originServerName` - Sets the SNI hostname for TLS handshake

### Phase 5: Add DNS Record

1. Login to Cloudflare Dashboard
2. Select domain: mykyta-ryasny.dev
3. Go to DNS → Records
4. Click "Add record"
5. Fill in:
   - **Type**: CNAME
   - **Name**: your-subdomain (just the subdomain part, e.g., `plex`)
   - **Target**: `07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com`
   - **Proxy status**: Proxied (orange cloud)
   - **TTL**: Auto
6. Click Save

### Phase 6: Deploy and Test

```bash
# Navigate to project directory
cd /opt/homeserver

# Create service directory if needed
mkdir -p ./services/your-service

# Start all services (will create only new ones)
docker compose up -d

# Check that your service started
docker compose ps

# Check logs for your service
docker compose logs -f your-service

# Check Caddy logs (should show your new site loaded)
docker compose logs caddy | grep -i your-subdomain

# Test internal connectivity
docker exec caddy curl -I http://your-service:PORT

# Test external access
curl -I https://your-subdomain.mykyta-ryasny.dev
```

---

## Examples

### Example 1: Plex Media Server

**docker-compose.yml:**
```yaml
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    restart: unless-stopped
    volumes:
      - ./services/plex/config:/config
      - ./media/tv:/tv
      - ./media/movies:/movies
    networks:
      - web
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
      - VERSION=docker
```

**Caddy configuration** (`services/caddy/sites/plex.caddy`):
```caddy
# ============================================================================
# Plex Media Server Configuration
# ============================================================================
# Container: plex
# Port: 32400
# ============================================================================

https://plex.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy plex:32400
}
```

**Cloudflare Tunnel** (add to `config.yml`):
```yaml
  - hostname: plex.mykyta-ryasny.dev
    service: https://caddy:443
    originRequest:
      noTLSVerify: true
      originServerName: plex.mykyta-ryasny.dev
```

**DNS Record:**
- Type: CNAME
- Name: plex
- Target: 07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com

### Example 2: qBittorrent

**docker-compose.yml:**
```yaml
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    volumes:
      - ./services/qbittorrent/config:/config
      - ./downloads:/downloads
    networks:
      - web
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
      - WEBUI_PORT=8080
```

**Caddy configuration** (`services/caddy/sites/qbittorrent.caddy`):
```caddy
# ============================================================================
# qBittorrent Configuration
# ============================================================================
# Container: qbittorrent
# Port: 8080
# ============================================================================

https://torrent.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy qbittorrent:8080
}
```

**Cloudflare Tunnel** (add to `config.yml`):
```yaml
  - hostname: torrent.mykyta-ryasny.dev
    service: https://caddy:443
    originRequest:
      noTLSVerify: true
      originServerName: torrent.mykyta-ryasny.dev
```

### Example 3: Static Website (Like current Hello World)

**docker-compose.yml:**
```yaml
  portfolio:
    image: nginx:alpine
    container_name: portfolio
    restart: unless-stopped
    volumes:
      - ./services/portfolio/html:/usr/share/nginx/html:ro
    networks:
      - web
```

**Caddy configuration** (`services/caddy/sites/portfolio.caddy`):
```caddy
# ============================================================================
# Portfolio Website Configuration
# ============================================================================
# Container: portfolio (nginx)
# Port: 80
# ============================================================================

# Main domain
https://portfolio.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy portfolio:80
}
```

---

## Troubleshooting

### Issue: Service not accessible externally (502 Bad Gateway)

**Check 1: Is the container running?**
```bash
docker compose ps
# Should show your service as "Up"
```

**Check 2: Is the service on the web network?**
```bash
docker inspect your-service | grep -A 5 Networks
# Should show "web" network
```

**Check 3: Can Caddy reach the service?**
```bash
docker exec caddy curl -I http://your-service:PORT
# Should return HTTP headers
```

**Check 4: Are there errors in logs?**
```bash
docker compose logs your-service
docker compose logs caddy
docker compose logs cloudflared
```

### Issue: DNS not resolving

**Wait for propagation:** DNS changes can take a few minutes

**Check DNS:**
```bash
nslookup subdomain.mykyta-ryasny.dev
# Should point to Cloudflare IPs
```

**Verify in Cloudflare Dashboard:** Make sure the CNAME record exists and is proxied

### Issue: Caddy not loading new configuration

**Reload Caddy:**
```bash
docker compose restart caddy
```

**Check for syntax errors:**
```bash
docker compose logs caddy | grep -i error
```

**Verify file permissions:**
```bash
ls -lah /opt/homeserver/services/caddy/sites/
# Files should be readable (644 permissions)
```

### Issue: Certificate errors

**Check certificate is mounted:**
```bash
docker exec caddy ls -lah /etc/caddy/certs/
# Should show origin.pem and origin.key
```

**Verify Cloudflare SSL mode:**
- Login to Cloudflare Dashboard
- SSL/TLS → Overview
- Should be set to "Full" (not Flexible or Full Strict)

### Issue: Import not working

**Verify sites directory is mounted:**
```bash
docker exec caddy ls -lah /etc/caddy/sites/
# Should show your .caddy files
```

**Recreate container if volume mounts changed:**
```bash
docker compose up -d --force-recreate caddy
```

---

## Best Practices

### Security
- Never expose database ports publicly
- Use strong passwords for web UIs
- Enable 2FA where available
- Regularly update Docker images

### Organization
- One service = one .caddy file
- Use descriptive subdomain names
- Comment your configurations
- Keep related services together in docker-compose.yml

### Backups
- Backup `/opt/homeserver/services/` directory regularly
- Backup Docker volumes (especially databases)
- Test restore procedures

### Monitoring
- Check logs regularly: `docker compose logs -f`
- Monitor disk usage: `df -h`
- Watch container resource usage: `docker stats`

---

## Quick Reference

### File Locations
```
/opt/homeserver/
├── docker-compose.yml              # Main orchestration file
├── services/
│   ├── caddy/
│   │   ├── Caddyfile              # Master config
│   │   ├── sites/                 # Individual service configs
│   │   │   ├── hello-world.caddy
│   │   │   └── your-service.caddy
│   │   └── certs/                 # Origin certificates
│   ├── cloudflared/
│   │   └── config.yml             # Tunnel configuration
│   └── your-service/
│       └── config/                # Service-specific config
```

### Common Commands
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart service-name

# View logs
docker compose logs -f service-name

# Update images and restart
docker compose pull && docker compose up -d

# Remove orphaned containers
docker compose down --remove-orphans
```

### Cloudflare Tunnel ID
```
07fbc124-6f0e-40c5-b254-3a1bdd98cf3c
```

Use this for all CNAME records: `TUNNEL_ID.cfargotunnel.com`
