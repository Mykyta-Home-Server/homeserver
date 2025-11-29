# Docker Compose Service Profiles

**Last Updated:** 2025-11-24

---

## Overview

Service profiles allow you to selectively start groups of services instead of everything at once. This is useful for:
- Testing specific components
- Reducing resource usage when you don't need all services
- Maintenance workflows
- Development and debugging

---

## Available Profiles

### 📺 `media` Profile
Media streaming and automation services.

**Includes:**
- Jellyfin (streaming)
- Jellyseerr (requests)
- qBittorrent (downloads)
- Radarr (movies)
- Sonarr (TV shows)
- Prowlarr (indexers)

**Usage:**
```bash
# Start only media services
docker compose --profile media up -d

# Stop media services
docker compose --profile media down
```

---

### 📊 `monitoring` Profile
Monitoring and logging stack.

**Includes:**
- Grafana (dashboards)
- Loki (log aggregation)
- Promtail (log collection)
- Uptime Kuma (uptime monitoring)

**Usage:**
```bash
# Start only monitoring services
docker compose --profile monitoring up -d

# Stop monitoring services
docker compose --profile monitoring down
```

---

### 🌟 `all` Profile
All services including media and monitoring.

**Usage:**
```bash
# Start all services with profiles
docker compose --profile all up -d

# Or start multiple profiles
docker compose --profile media --profile monitoring up -d
```

---

## Services Without Profiles

The following core services run by default (no profile needed):
- Caddy (reverse proxy)
- Cloudflared (Cloudflare Tunnel)
- Authelia (authentication)
- PostgreSQL (database)
- Redis (cache)
- Watchtower (container updates)
- Portal (home dashboard)

These are essential infrastructure services that should always be running.

---

## Common Use Cases

### Case 1: Start Everything
```bash
cd /opt/homeserver
docker compose --profile all up -d
```

### Case 2: Only Core + Media
```bash
# Core services start automatically
docker compose --profile media up -d
```

### Case 3: Only Core + Monitoring
```bash
docker compose --profile monitoring up -d
```

### Case 4: Restart Specific Profile
```bash
# Restart just media services
docker compose --profile media restart
```

### Case 5: Stop Specific Profile (Keep Core Running)
```bash
# Stop media services but keep core running
docker compose --profile media stop
```

### Case 6: View Services in a Profile
```bash
# See what would start with media profile
docker compose --profile media config --services
```

---

## Checking What's Running

```bash
# See all running containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# See containers by group label
docker ps --filter "label=com.homeserver.group=media"
docker ps --filter "label=com.homeserver.group=monitoring"
```

---

## Important Notes

1. **Core services always start**: Services without profiles (proxy, auth, etc.) start automatically with any `docker compose up` command.

2. **Profile required to start**: Services WITH profiles will NOT start unless you specify their profile.

3. **Multiple profiles**: You can activate multiple profiles in one command:
   ```bash
   docker compose --profile media --profile monitoring up -d
   ```

4. **Updating with profiles**: When running `docker compose up -d` to update services, remember to include the profiles:
   ```bash
   docker compose --profile all up -d
   ```

5. **Watchtower compatibility**: Watchtower will update containers regardless of profiles, but they won't auto-restart if their profile isn't active.

---

## Troubleshooting

### Service not starting?
```bash
# Check if it requires a profile
docker compose config | grep -A 2 "your-service-name"

# Start with the correct profile
docker compose --profile all up -d
```

### Want to remove profiles temporarily?
You can comment out the `profiles:` line in the compose file, but it's better to use `--profile all` instead.

---

## Examples

```bash
# Start everything for production
docker compose --profile all up -d

# Testing: Start only monitoring while working on it
docker compose --profile monitoring up -d

# Maintenance: Stop media services to save resources
docker compose --profile media stop

# When done with maintenance, restart them
docker compose --profile media start
```

---

**Related Files:**
- [docker-compose.yml](../docker-compose.yml) - Main compose file
- [compose/media.yml](../compose/media.yml) - Media services definitions
- [compose/monitoring.yml](../compose/monitoring.yml) - Monitoring services definitions
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - General Docker commands
