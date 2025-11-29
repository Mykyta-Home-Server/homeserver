# Service Configurations

This directory contains configuration files that are mounted into Docker containers as volumes.

## Purpose

The `services/` directory stores **configuration files only** - not data, cache, or generated files. These configs are:
- ✅ Version controlled in git
- ✅ Mounted read-only when possible
- ✅ Small, human-readable text files

## Structure

```
services/
├── proxy/              # Reverse proxy configuration
│   └── caddy/
│       ├── Caddyfile              # Main Caddy config
│       ├── sites/                 # Per-service Caddyfile configs
│       ├── certs/                 # Cloudflare Origin Certificates
│       ├── data/                  # Caddy generated data (gitignored)
│       └── config/                # Caddy generated config (gitignored)
│
├── tunnel/             # Cloudflare Tunnel
│   └── cloudflared/
│       ├── config.yml             # Tunnel routes
│       └── credentials.json       # Tunnel credentials (gitignored)
│
├── auth/               # Authentication stack
│   ├── authelia/
│   │   └── configuration.yml      # Authelia SSO config
│   ├── postgres/
│   │   └── data/                  # Database files (gitignored)
│   ├── redis/
│   │   └── data/                  # Redis persistence (gitignored)
│   └── ldap/
│       ├── database/              # LDAP data (gitignored)
│       ├── config/                # LDAP slapd config (gitignored)
│       └── certs/                 # LDAP TLS certs (gitignored)
│
├── monitoring/         # Monitoring stack
│   ├── grafana/
│   │   ├── grafana.ini            # Grafana config
│   │   ├── provisioning/          # Datasources & dashboards
│   │   └── data/                  # Grafana data (gitignored)
│   ├── loki/
│   │   ├── loki-config.yml        # Loki config
│   │   └── data/                  # Log storage (gitignored)
│   └── promtail/
│       ├── promtail-config.yml    # Promtail config
│       └── positions/             # Log positions (gitignored)
│
├── media/              # Media services
│   ├── jellyfin/
│   │   ├── config/                # Jellyfin config (gitignored)
│   │   └── cache/                 # Transcoding cache (gitignored)
│   ├── sonarr/
│   │   └── config/                # Sonarr config (gitignored)
│   ├── radarr/
│   │   └── config/                # Radarr config (gitignored)
│   ├── prowlarr/
│   │   └── config/                # Prowlarr config (gitignored)
│   ├── jellyseerr/
│   │   └── config/                # Jellyseerr config (gitignored)
│   └── qbittorrent/
│       └── config/                # qBittorrent config (gitignored)
│
├── web/                # Web applications
│   ├── portal/                    # Angular dashboard (gitignored - deployed via GitHub)
│   └── hello-world/
│       └── index.html             # Test page
│
└── github-runner/      # CI/CD runner
    └── (runtime files)            # GitHub Actions runner data (gitignored)
```

## What Goes Here vs. /data/

| Directory | Purpose | Examples | Version Control |
|-----------|---------|----------|-----------------|
| `/opt/homeserver/services/` | **Configuration** | YAML, INI, Caddyfiles | ✅ Yes (most files) |
| `/opt/homeserver/data/` | **Media & Large Files** | Movies, TV shows, downloads | ❌ No (gitignored) |
| Generated data within services/ | **Container-generated** | Database files, caches | ❌ No (gitignored) |

## Security Notes

⚠️ **Never commit:**
- Secrets (use `/opt/homeserver/secrets/` with Docker secrets)
- Credentials (tunnel credentials, API keys)
- Database files
- User data

✅ **Safe to commit:**
- Configuration templates
- Caddyfiles (without secrets)
- Dashboards (Grafana JSON)
- Provisioning files

## Modifying Configs

When modifying configuration files:

1. **Edit the file** in this directory
2. **Reload the service**:
   ```bash
   # For Caddy (live reload)
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile

   # For most other services (restart required)
   docker compose restart <service-name>
   ```
3. **Verify changes**:
   ```bash
   docker compose logs -f <service-name>
   ```

## Adding a New Service

1. Create service directory: `mkdir -p services/newservice/`
2. Add configuration files
3. Mount in `compose/<category>/<service>.yml`:
   ```yaml
   volumes:
     - ../../services/newservice/config.yml:/app/config.yml:ro
   ```
4. Add to `.gitignore` if it contains generated data:
   ```
   services/newservice/data/
   ```

## Backup

Configuration files in this directory are included in automated backups (`/opt/homeserver/scripts/backup.sh`).

Large data directories (`data/`, `cache/`, etc.) are **not** backed up automatically and should be handled separately.
