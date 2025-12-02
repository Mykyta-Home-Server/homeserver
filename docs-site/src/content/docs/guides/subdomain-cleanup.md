---
title: Subdomain Cleanup After Authentik Migration
description: Remove unused subdomains and update Authentik to final domain
---

## Overview

After the Authentik migration, several subdomains need to be cleaned up and the SSO domain should be moved to its permanent location.

---

## Subdomains to Remove

### 1. Uptime Kuma - `uptime.mykyta-ryasny.dev`

**Status:** Configured in tunnel but service doesn't exist

**Reason for removal:** Uptime Kuma was planned but never deployed. Monitoring is handled by Grafana + Loki instead.

**Steps:**
1. Remove from `services/tunnel/cloudflared/config.yml`:
   ```yaml
   # DELETE THIS ENTRY:
   - hostname: uptime.mykyta-ryasny.dev
     service: https://caddy:443
     originRequest:
       noTLSVerify: true
       originServerName: uptime.mykyta-ryasny.dev
   ```

2. Restart tunnel:
   ```bash
   docker compose restart cloudflared
   ```

3. Delete DNS record in Cloudflare dashboard:
   - Go to DNS → Records
   - Delete CNAME: `uptime` → tunnel

---

### 2. Deployment API - `deploy.mykyta-ryasny.dev`

**Status:** Configured in tunnel but service doesn't exist

**Reason for removal:** No deployment API service was ever created. Deployments are handled via GitHub Actions self-hosted runner.

**Steps:**
1. Remove from `services/tunnel/cloudflared/config.yml`:
   ```yaml
   # DELETE THIS ENTRY:
   - hostname: deploy.mykyta-ryasny.dev
     service: https://caddy:443
     originRequest:
       noTLSVerify: true
       originServerName: deploy.mykyta-ryasny.dev
   ```

2. Restart tunnel:
   ```bash
   docker compose restart cloudflared
   ```

3. Delete DNS record in Cloudflare dashboard:
   - Go to DNS → Records
   - Delete CNAME: `deploy` → tunnel

---

## Verification Checklist

After cleanup:

- [ ] `uptime.mykyta-ryasny.dev` removed from tunnel and DNS
- [ ] `deploy.mykyta-ryasny.dev` removed from tunnel and DNS
- [ ] Authentik accessible at `sso.mykyta-ryasny.dev`
- [ ] Portal successfully calls `sso.mykyta-ryasny.dev/api/v3/core/users/me/`
- [ ] Logout redirects to `sso.mykyta-ryasny.dev`
- [ ] All protected services still accessible and authenticated

---

## Rollback Plan

**If subdomain cleanup causes issues:**

1. **Revert tunnel config:**
   ```bash
   git checkout services/tunnel/cloudflared/config.yml
   docker compose restart cloudflared
   ```

2. **Restore DNS records:**
   - Re-create CNAME records in Cloudflare for removed subdomains if needed

---

## Final Subdomain List

**After cleanup, active subdomains:**

| Subdomain | Full Domain | Service |
|-----------|-------------|---------|
| `sso` | `sso.mykyta-ryasny.dev` | Authentik SSO |
| `home` | `home.mykyta-ryasny.dev` | Portal Dashboard |
| `streaming` | `streaming.mykyta-ryasny.dev` | Jellyfin |
| `requests` | `requests.mykyta-ryasny.dev` | Jellyseerr |
| `movies` | `movies.mykyta-ryasny.dev` | Radarr |
| `tv` | `tv.mykyta-ryasny.dev` | Sonarr |
| `indexers` | `indexers.mykyta-ryasny.dev` | Prowlarr |
| `bazarr` | `bazarr.mykyta-ryasny.dev` | Bazarr |
| `torrent` | `torrent.mykyta-ryasny.dev` | qBittorrent |
| `monitor` | `monitor.mykyta-ryasny.dev` | Grafana |

**Total:** 10 active subdomains (cleaner, more maintainable)
