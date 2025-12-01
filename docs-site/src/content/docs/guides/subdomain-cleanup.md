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

## Move Authentik to Final Domain

### Current State

- **Current domain:** `sso.mykyta-ryasny.dev` (temporary during migration)
- **Final domain:** `auth.mykyta-ryasny.dev` (permanent)

**Why move:**
- `auth.` is more consistent with service naming
- `sso.` was temporary to avoid conflicts during migration

---

### Migration Steps

**⚠️ Downtime:** ~2-3 minutes during DNS propagation and container restart.

#### 1. Update Caddy Configuration

Edit `services/proxy/caddy/sites/authentik.Caddyfile`:

```diff
- sso.mykyta-ryasny.dev {
+ auth.mykyta-ryasny.dev {
     import cf_tls

     # CORS headers for API endpoints (allow portal to access user info)
     @api path /api/*
     handle @api {
         header {
-            Access-Control-Allow-Origin "https://home.mykyta-ryasny.dev"
+            Access-Control-Allow-Origin "https://home.mykyta-ryasny.dev"  # No change needed
             Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
             Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
             Access-Control-Allow-Credentials "true"
             Access-Control-Max-Age "3600"
         }

         @options method OPTIONS
         respond @options 204

         reverse_proxy authentik-server:9000
     }

     handle {
         reverse_proxy authentik-server:9000
     }
 }
```

#### 2. Update Cloudflare Tunnel

Edit `services/tunnel/cloudflared/config.yml`:

```diff
   # Authentication - Authentik SSO portal
-  - hostname: sso.mykyta-ryasny.dev
+  - hostname: auth.mykyta-ryasny.dev
     service: https://caddy:443
     originRequest:
       noTLSVerify: true
-      originServerName: sso.mykyta-ryasny.dev
+      originServerName: auth.mykyta-ryasny.dev
```

#### 3. Update Portal API Calls

In the `homeserver-portal` repository, update `src/app/core/services/auth.service.ts`:

```diff
  loadUserInfo(): void {
    // ... loading logic ...

    this.http.get<AuthentikUser>(
-     'https://sso.mykyta-ryasny.dev/api/v3/core/users/me/',
+     'https://auth.mykyta-ryasny.dev/api/v3/core/users/me/',
      { withCredentials: true }
    ).subscribe({
      // ... subscription logic ...
    });
  }
```

Update `src/app/shared/components/header/header.component.ts`:

```diff
  <!-- Logout -->
  <a
-   href="https://sso.mykyta-ryasny.dev/if/flow/default-invalidation-flow/"
+   href="https://auth.mykyta-ryasny.dev/if/flow/default-invalidation-flow/"
    class="px-4 py-2 text-sm rounded-lg bg-theme-tertiary text-theme-secondary
           hover:text-error transition-colors"
  >
    Logout
  </a>
```

**Commit changes:**
```bash
git commit -m "fix: update Authentik domain from sso to auth"
git push origin main
```

**Wait for CI/CD:** Let GitHub Actions build and deploy the updated portal.

#### 4. Update Cloudflare DNS

1. Go to Cloudflare dashboard → DNS → Records
2. Create new CNAME record:
   - **Name:** `auth`
   - **Target:** `07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com`
   - **Proxy status:** Proxied (orange cloud)
   - **TTL:** Auto
3. **Keep** `sso` record temporarily for testing

#### 5. Restart Services

```bash
# Restart reverse proxy and tunnel
docker compose restart caddy cloudflared

# Verify Caddy loaded new config
docker compose logs caddy | tail -20
```

#### 6. Test New Domain

```bash
# Test HTTPS access
curl -I https://auth.mykyta-ryasny.dev

# Expected: HTTP/2 200

# Test CORS headers
curl -i -X OPTIONS \
  -H "Origin: https://home.mykyta-ryasny.dev" \
  -H "Access-Control-Request-Method: GET" \
  https://auth.mykyta-ryasny.dev/api/v3/core/users/me/

# Expected headers:
# Access-Control-Allow-Origin: https://home.mykyta-ryasny.dev
# Access-Control-Allow-Credentials: true
```

#### 7. Test Portal

1. Open portal: `https://home.mykyta-ryasny.dev`
2. Check browser DevTools → Console for errors
3. Verify user info loads (check Network tab for `/api/v3/core/users/me/` call)
4. Test logout (should redirect to `auth.mykyta-ryasny.dev`)
5. Test login (should redirect back to portal)

#### 8. Remove Old Domain

**After confirming everything works (wait 24-48 hours):**

1. Delete from `services/tunnel/cloudflared/config.yml`:
   ```yaml
   # DELETE after migration complete:
   - hostname: sso.mykyta-ryasny.dev
     service: https://caddy:443
     originRequest:
       noTLSVerify: true
       originServerName: sso.mykyta-ryasny.dev
   ```

2. Delete from `services/proxy/caddy/sites/`:
   - Remove or update any references to `sso.mykyta-ryasny.dev`

3. Restart services:
   ```bash
   docker compose restart caddy cloudflared
   ```

4. Delete DNS record in Cloudflare:
   - Delete CNAME: `sso` → tunnel

---

## Verification Checklist

After cleanup:

- [ ] `uptime.mykyta-ryasny.dev` removed from tunnel and DNS
- [ ] `deploy.mykyta-ryasny.dev` removed from tunnel and DNS
- [ ] Authentik accessible at `auth.mykyta-ryasny.dev`
- [ ] Portal successfully calls `auth.mykyta-ryasny.dev/api/v3/core/users/me/`
- [ ] Logout redirects to `auth.mykyta-ryasny.dev`
- [ ] All protected services still accessible and authenticated
- [ ] `sso.mykyta-ryasny.dev` removed (after 24-48 hour grace period)

---

## Rollback Plan

**If the auth domain move fails:**

1. **Revert Caddy config:**
   ```bash
   git checkout services/proxy/caddy/sites/authentik.Caddyfile
   docker compose restart caddy
   ```

2. **Revert tunnel config:**
   ```bash
   git checkout services/tunnel/cloudflared/config.yml
   docker compose restart cloudflared
   ```

3. **Revert portal (if deployed):**
   - Revert the commit in `homeserver-portal`
   - Push to trigger redeployment

4. **DNS:** Keep `sso` record, delete `auth` record if created

---

## Final Subdomain List

**After cleanup, active subdomains:**

| Subdomain | Full Domain | Service |
|-----------|-------------|---------|
| `auth` | `auth.mykyta-ryasny.dev` | Authentik SSO |
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
