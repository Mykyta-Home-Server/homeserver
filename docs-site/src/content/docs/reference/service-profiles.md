---
title: Service Profiles
description: Docker Compose profiles for managing service groups
---

Docker Compose profiles allow selective service deployment.

## Available Profiles

| Profile | Services |
|---------|----------|
| `(default)` | Infrastructure + Auth (Caddy, Cloudflared, Authelia, PostgreSQL, Redis) |
| `web` | Portal, hello-world |
| `media` | Jellyfin, Sonarr, Radarr, Prowlarr, Jellyseerr, qBittorrent, Bazarr, FlareSolverr |
| `monitoring` | Grafana, Loki, Promtail |
| `maintenance` | maintenance-cron |
| `cicd` | GitHub Actions runner |
| `all` | Everything |

## Usage

### Start default services
```bash
docker compose up -d
```

### Start specific profile
```bash
docker compose --profile media up -d
```

### Start multiple profiles
```bash
docker compose --profile media --profile monitoring up -d
```

### Start everything
```bash
docker compose --profile all up -d
```

## Profile Definition

In `compose/media/jellyfin.yml`:

```yaml
services:
  jellyfin:
    profiles: ["media", "all"]
    image: lscr.io/linuxserver/jellyfin:latest
    # ...
```

## Checking Active Services

```bash
# List all running containers
docker compose ps

# List services for a profile
docker compose --profile media config --services
```

## Common Operations

### Start media stack
```bash
docker compose --profile media up -d
```

### Stop media stack (keep other services)
```bash
docker compose --profile media down
```

### Restart single service
```bash
docker compose restart jellyfin
```

### Update media stack
```bash
docker compose --profile media pull
docker compose --profile media up -d
```
