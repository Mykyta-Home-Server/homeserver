# Session 3: Media Automation Stack Setup

**Date:** 2025-11-22
**Duration:** ~2 hours
**Focus:** Setting up complete media automation stack (Jellyfin + Arr Stack)

---

## Accomplishments

### 1. ✅ Infrastructure Refactoring
- **Split monolithic docker-compose.yml** into modular files using `include:` directive
  - `compose/proxy.yml` - Caddy reverse proxy
  - `compose/tunnel.yml` - Cloudflare Tunnel
  - `compose/web.yml` - Static websites
  - `compose/media.yml` - Media automation services

- **Reorganized service directories** by function:
  ```
  services/
  ├── proxy/caddy/          # Reverse proxy configs
  ├── tunnel/cloudflared/   # Tunnel configuration
  ├── web/hello-world/      # Static sites
  └── media/                # Media services
      ├── jellyfin/
      ├── qbittorrent/
      ├── radarr/
      ├── sonarr/
      ├── prowlarr/
      └── jellyseerr/
  ```

### 2. ✅ Media Services Deployed
Installed and configured complete media automation stack:

| Service | Purpose | Subdomain | Port |
|---------|---------|-----------|------|
| **Jellyfin** | Media streaming server | streaming.mykyta-ryasny.dev | 8096 |
| **qBittorrent** | Torrent client | torrent.mykyta-ryasny.dev | 8080 |
| **Radarr** | Movie automation | movies.mykyta-ryasny.dev | 7878 |
| **Sonarr** | TV show automation | tv.mykyta-ryasny.dev | 8989 |
| **Prowlarr** | Indexer manager | indexers.mykyta-ryasny.dev | 9696 |
| **Jellyseerr** | Request management | requests.mykyta-ryasny.dev | 5055 |

### 3. ✅ Configuration Updates
- **Timezone**: Changed all services to `Europe/Madrid`
- **File extensions**: Renamed `.caddy` → `.Caddyfile` for syntax highlighting
- **Basic auth**: Added password protection to admin services (qBittorrent, Radarr, Sonarr, Prowlarr)
- **Cloudflare Tunnel**: Added all 6 media subdomains to tunnel configuration

---

## Key Learnings & Critical Fixes

### 🔴 CRITICAL: Cloudflare DNS Proxy Status
**Problem:** Media subdomains were timing out even though configuration was correct.

**Root Cause:** DNS records were set to "DNS only" (grey cloud) instead of "Proxied" (orange cloud).

**Why it matters:**
- Cloudflare Tunnel requires DNS records to be **Proxied (orange cloud)**
- "DNS only" mode bypasses Cloudflare's routing layer
- Without Proxied mode, requests don't reach the tunnel

**Solution:** Changed all media subdomain DNS records from grey cloud → orange cloud in Cloudflare dashboard.

**Lesson:** Always verify proxy status when adding new subdomains!

### 🔴 CRITICAL: Caddyfile Site Block Format
**Problem:** Initially had TLS handshake errors.

**Root Cause:** Site blocks must use `https://` prefix.

**Correct format:**
```caddy
https://subdomain.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy service:port
}
```

**Lesson:** ALWAYS use `https://` prefix in Caddyfile site blocks.

### 🔴 Container Startup Order
**Problem:** Cloudflared tried to connect to Caddy before Caddy was ready, causing "connection refused" errors.

**Root Cause:** Cloudflared was starting before Caddy finished loading.

**Current Status:** Using `depends_on: - caddy` in tunnel.yml helps, but not guaranteed. Cloudflared auto-reconnects, so temporary failures during startup are normal.

**Lesson:** Check cloudflared logs for connection errors after restart. They should disappear once Caddy is fully up.

### File Organization Best Practices
**Discovered during refactoring:**
- Docker Compose v2.20+ supports `include:` directive for modular configs
- Group services by function (proxy, tunnel, web, media, monitoring)
- Use relative paths with `../` from compose subdirectory
- Consistent naming: folder name = container name = service name

---

## Technical Details

### Docker Compose Include Directive
```yaml
# /opt/homeserver/docker-compose.yml
include:
  - compose/proxy.yml
  - compose/tunnel.yml
  - compose/web.yml
  - compose/media.yml

networks:
  web:
    name: web
    driver: bridge
```

**Benefits:**
- Easier to manage (each file ~50-100 lines)
- Clear separation of concerns
- Simpler troubleshooting
- Modular: can disable entire categories

### Cloudflare Tunnel Configuration Pattern
```yaml
ingress:
  - hostname: subdomain.mykyta-ryasny.dev
    service: https://caddy:443
    originRequest:
      noTLSVerify: true                          # Don't verify Cloudflare Origin Cert
      originServerName: subdomain.mykyta-ryasny.dev  # SNI for TLS handshake
```

**Why this works:**
- `service: https://caddy:443` - Connects to Caddy via HTTPS (not HTTP)
- `noTLSVerify: true` - Cloudflare Origin Certs aren't signed by public CA
- `originServerName` - Sets correct SNI so Caddy knows which site to serve

### Caddy Configuration Pattern
```caddy
https://subdomain.mykyta-ryasny.dev {
    import cf_tls                        # Loads Cloudflare Origin Certificate

    basicauth {                          # Optional: for admin services
        admin $2a$14$hash...
    }

    reverse_proxy container-name:port
}
```

---

## Troubleshooting Process

When subdomains weren't working, we systematically checked:

1. ✅ **Docker containers running** - All 6 media services up
2. ✅ **Caddy configuration valid** - No syntax errors
3. ✅ **Internal network connectivity** - Caddy could reach all services
4. ✅ **DNS resolution** - Subdomains resolved to tunnel CNAME
5. ✅ **Cloudflare Tunnel connected** - 4 active connections to Madrid
6. ❌ **Cloudflared receiving requests** - NO requests in logs ← Found the issue!
7. 🔍 **DNS query** - Resolved to Cloudflare proxy IPs (not tunnel CNAME)
8. 🔴 **Root cause** - DNS records were "DNS only" instead of "Proxied"

**Debugging commands used:**
```bash
# Check container status
docker ps

# Verify Caddy config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Test internal connectivity
docker exec caddy ping -c 2 jellyfin

# Check DNS resolution
dig +short streaming.mykyta-ryasny.dev
dig +short streaming.mykyta-ryasny.dev @1.1.1.1

# Monitor tunnel logs
docker logs cloudflared --follow

# Test specific hostname
curl -I https://streaming.mykyta-ryasny.dev
```

---

## Configuration Files Modified

### Created/Updated Files
1. **compose/media.yml** - New file with all 6 media services
2. **services/proxy/caddy/sites/media.Caddyfile** - All media subdomain routes
3. **services/tunnel/cloudflared/config.yml** - Added 6 media subdomains
4. **docs/adding-services.md** - Updated with critical requirements section
5. **sessions/SESSION_3_MEDIA_STACK.md** - This file

### Key Configuration Snippets

**Basic auth password hash:**
```
admin:$2a$14$lkU8UEFcjHC0SiIe/KpdGelgq48qR7QCWIStlSj3mt05KPPWGHTvS
```
(Password: your chosen password)

**Cloudflare Tunnel ID:**
```
07fbc124-6f0e-40c5-b254-3a1bdd98cf3c
```

**All Media Subdomains:**
- torrent.mykyta-ryasny.dev
- streaming.mykyta-ryasny.dev
- movies.mykyta-ryasny.dev
- tv.mykyta-ryasny.dev
- indexers.mykyta-ryasny.dev
- requests.mykyta-ryasny.dev

---

## Next Steps (For Next Session)

### Immediate Todo
1. ✅ Configure Prowlarr with torrent indexers
2. ✅ Connect Radarr to Prowlarr and qBittorrent
3. ✅ Connect Sonarr to Prowlarr and qBittorrent
4. ✅ Configure Jellyfin library paths
5. ✅ Connect Jellyseerr to Jellyfin, Radarr, and Sonarr

### Automation & Notifications
6. Create Telegram bots (personal and admin/monitoring)
7. Set up Telegram notifications in Radarr
8. Set up Telegram notifications in Sonarr
9. Set up Telegram notifications in Jellyseerr
10. Configure disk space monitoring with Telegram alerts
11. Set up cron jobs for monitoring scripts

### Testing
12. Test complete workflow: Request movie → Download → Organize → Notify
13. Test complete workflow: Request TV show → Download → Organize → Notify

---

## Infrastructure Status

### ✅ Working Services
- Caddy reverse proxy (all sites accessible)
- Cloudflare Tunnel (4 active connections)
- Hello World (mykyta-ryasny.dev)
- All 6 media services accessible via HTTPS

### 📊 System Health
- All containers running
- No errors in logs
- Network connectivity verified
- DNS propagated and working
- SSL certificates valid

### 🎯 Project Progress
**Phase 1: Foundation** ✅ Complete
- Hardware, OS, Docker basics

**Phase 2: Core Services** ✅ Complete
- Media stack deployed and accessible

**Phase 3: Networking** ✅ Complete
- Domain, Cloudflare, Caddy, subdomain routing

**Phase 4: Advanced Services** 🔄 In Progress
- Media automation (partially configured)

**Phase 5: Automation** ⏳ Pending
- MCP server, Telegram bot, natural language control

**Phase 6: Refinement** ⏳ Pending
- Monitoring, backups, optimization

---

## Commands Reference

### Service Management
```bash
# Navigate to project
cd /opt/homeserver

# View all running containers
docker ps

# Start all services
docker compose up -d

# Restart specific service
docker compose restart servicename

# View logs
docker compose logs -f servicename

# Check tunnel status
docker logs cloudflared --tail 20
```

### Troubleshooting
```bash
# Test Caddy can reach service
docker exec caddy ping -c 2 jellyfin

# Validate Caddy config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Check which domains Caddy loaded
docker exec caddy caddy adapt --config /etc/caddy/Caddyfile 2>&1 | grep '"host"' | sort -u

# Test DNS resolution
dig +short subdomain.mykyta-ryasny.dev
```

---

## Important Reminders

### Before Adding New Services
1. ✅ Add to appropriate compose/*.yml file
2. ✅ Create Caddyfile in sites/ directory (with `https://` prefix!)
3. ✅ Update Cloudflare Tunnel config.yml
4. ✅ Add DNS CNAME record in Cloudflare
5. ✅ **Set DNS to Proxied (orange cloud)** ⚠️
6. ✅ Wait 30-60 seconds for DNS propagation
7. ✅ Test access via browser

### Common Mistakes to Avoid
- ❌ Forgetting `https://` in Caddyfile site blocks
- ❌ Setting DNS to "DNS only" (grey cloud) instead of Proxied
- ❌ Not adding subdomain to tunnel config.yml
- ❌ Wrong paths in compose files (use `../services` not `./services`)
- ❌ Forgetting to restart containers after config changes

---

## Session Metrics

**Time Spent:**
- Infrastructure refactoring: 30 min
- Service deployment: 20 min
- Troubleshooting DNS/tunnel: 60 min
- Documentation: 20 min

**Key Achievement:** Learned critical DNS proxy requirement for Cloudflare Tunnels

**Most Valuable Lesson:** Always verify Cloudflare DNS proxy status (orange cloud) when troubleshooting subdomain connectivity issues.
