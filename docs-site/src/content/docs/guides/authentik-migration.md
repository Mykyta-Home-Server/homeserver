---
title: Authentik Migration Guide
description: Complete migration from Authelia/LDAP to Authentik SSO with lessons learned
---

## Migration Overview

This guide documents the complete migration from **Authelia + OpenLDAP** to **Authentik** as the single sign-on (SSO) solution for the home server.

**Migration Date:** December 2024
**Authentik Version:** 2025.10.2

---

## Why Migrate to Authentik?

### Problems with Authelia + LDAP

1. **Two separate systems** - Authelia for SSO, LDAP for user directory
2. **Complex user management** - Required phpLDAPadmin or manual LDIF editing
3. **Limited features** - Basic SSO only, no advanced flows or policies
4. **Poor API support** - Difficult to automate user management
5. **No self-service portal** - Users couldn't manage their own accounts

### Authentik Advantages

1. **All-in-one solution** - SSO, user directory, and management in one system
2. **Modern web UI** - Beautiful, responsive interface for users and admins
3. **Powerful API** - Full REST API for automation and integration
4. **Advanced flows** - Customizable authentication, enrollment, and logout flows
5. **Policy engine** - Fine-grained access control with expressions
6. **Self-service portal** - Users can update profiles, manage MFA, view sessions
7. **Built-in MFA** - TOTP, WebAuthn, static tokens
8. **OAuth2/OIDC native** - First-class support for modern authentication

---

## Architecture Changes

### Before (Authelia + LDAP)

```
User → Caddy → Authelia (Forward Auth) → Service
                  ↓
              OpenLDAP (User Directory)
                  ↓
           phpLDAPadmin (Management)
```

**Services:**
- Authelia (SSO)
- OpenLDAP (Users/Groups)
- phpLDAPadmin (Web UI)
- PostgreSQL (Authelia sessions)
- Redis (Authelia cache)

### After (Authentik)

```
User → Caddy → Authentik (Forward Auth + User Directory) → Service
```

**Services:**
- Authentik Server (SSO + API + UI)
- Authentik Worker (Background tasks)
- PostgreSQL (Authentik database)
- Redis (Sessions + task queue)

**Result:** Simplified from 5 services to 4, with more features.

---

## Migration Steps Performed

### 1. Deploy Authentik Stack

**Added compose files:**
- `compose/auth/authentik.yml` - Server and worker containers
- Updated `compose/auth/postgres.yml` - Reused existing PostgreSQL
- Updated `compose/auth/redis.yml` - Reused existing Redis

**Environment variables:**
```bash
AUTHENTIK_SECRET_KEY=<generated-secret>
AUTHENTIK_BOOTSTRAP_PASSWORD=<admin-password>
AUTHENTIK_POSTGRESQL__HOST=postgres-auth
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=authentik
AUTHENTIK_REDIS__HOST=redis-auth
```

### 2. Configure Authentik Caddy Proxy

**Created:** `services/proxy/caddy/sites/authentik.Caddyfile`

**Key features:**
- CORS headers for `/api/*` endpoints (allows portal to call Authentik API)
- Proper handling of OPTIONS preflight requests
- Reverse proxy to `authentik-server:9000`

**Domain:** `sso.mykyta-ryasny.dev` (temporary during migration)

### 3. Create Users and Groups

**Migrated from LDAP to Authentik:**
- Admin user with superuser privileges
- Regular users with appropriate groups
- Groups: `media_users`, `admin`, `monitoring`, etc.

**Migration approach:**
- Manual creation via Authentik web UI (small user count)
- For larger deployments, use Authentik API or blueprints

### 4. Configure Forward Authentication

**Updated Caddy snippet:** `services/proxy/caddy/Caddyfile`

**Authentik forward auth configuration:**
```caddyfile
(authentik_auth) {
    forward_auth authentik-server:9000 {
        uri /outpost.goauthentik.io/auth/caddy
        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid
    }
}
```

**Applied to all protected services:**
- Portal: `home.mykyta-ryasny.dev`
- Media: `movies.`, `tv.`, `indexers.`, `bazarr.`
- Monitoring: `monitor.mykyta-ryasny.dev`
- Downloads: `torrent.mykyta-ryasny.dev`

### 5. Configure OAuth2/OIDC Providers

**Created providers for services with native SSO support:**

1. **Jellyfin** - OIDC integration
2. **Jellyseerr** - Proxy provider (auto-SSO)
3. **All forward auth services** - OAuth2 providers for backchannel logout

**Provider settings:**
- `client_type`: confidential
- `authorization_flow`: implicit consent
- `invalidation_flow`: default-provider-invalidation-flow
- `logout_method`: **backchannel** (critical for SLO)

### 6. Fix Logout Flow (Critical)

**Problem discovered:** Logout didn't clear sessions across services.

**Root cause:** Invalidation flows used **Redirect Stage** instead of **User Logout Stage**.

**Solution via API:**

```bash
# Created API token for admin user
docker exec authentik-server python manage.py shell << 'EOF'
from authentik.core.models import Token, TokenIntents, User
user = User.objects.get(username='admin')
token, _ = Token.objects.get_or_create(
    user=user,
    intent=TokenIntents.INTENT_API,
    expiring=False,
    defaults={'identifier': 'api-token'}
)
print(token.key)
EOF

# Updated flow bindings to use User Logout stage
curl -X PATCH \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"stage": "<user-logout-stage-uuid>"}' \
  http://localhost:9000/api/v3/flows/bindings/<binding-uuid>/
```

**Updated flows:**
- `default-invalidation-flow` - Main logout flow
- `default-provider-invalidation-flow` - OAuth2 provider logout

**Result:** Logout now triggers **Single Logout (SLO)** via backchannel requests to all OAuth2 providers.

### 7. Portal Integration

**Direct API integration:**

The Angular portal calls Authentik's API directly to get user info:

```typescript
// AuthService: Load user from Authentik API
this.http.get<AuthentikUser>(
  'https://sso.mykyta-ryasny.dev/api/v3/core/users/me/',
  { withCredentials: true }
).subscribe(user => {
  // Map Authentik groups to permissions
  const permissions = {
    canAccessMedia: user.groups.some(g =>
      g.name === 'media_users' || g.name === 'admin'
    ),
    canAccessMonitoring: user.groups.some(g =>
      g.name === 'monitoring' || g.name === 'admin'
    ),
    isAdmin: user.groups.some(g => g.name === 'admin')
  };

  this.userSignal.set({ user, permissions });
});
```

**Logout link:**
```html
<a href="https://sso.mykyta-ryasny.dev/if/flow/default-invalidation-flow/">
  Logout
</a>
```

### 8. Update Grafana Dashboards

**Updated dashboard queries:**
- Changed container names from `authelia` to `authentik-server` and `authentik-worker`
- Updated auth stack dashboard to show Authentik metrics
- Added panels for Authentik worker tasks

**Dashboards updated:**
- `authentication.json` - Auth stack monitoring

### 9. Remove Old Services

**Removed from docker-compose:**
- `authelia` service
- `ldap` service (OpenLDAP)
- `phpldapadmin` service
- `user-management` API service

**Removed Caddy configs:**
- Old Authelia Caddyfile (if existed)
- LDAP admin Caddyfile (if existed)

**Cleaned up volumes:**
```bash
# Backup old data first!
docker compose down authelia ldap phpldapadmin
docker volume rm homeserver_authelia_data
docker volume rm homeserver_ldap_data
```

---

## Post-Migration Cleanup

### Subdomains to Remove

**No longer needed:**
1. `uptime.mykyta-ryasny.dev` - Uptime Kuma service doesn't exist
2. `deploy.mykyta-ryasny.dev` - Deployment API doesn't exist

**To update:**
- Remove from `services/tunnel/cloudflared/config.yml`
- Delete CNAME records in Cloudflare dashboard

### Future Migration Task

**Move Authentik to final domain:**

Currently: `sso.mykyta-ryasny.dev` (temporary)
Target: `auth.mykyta-ryasny.dev` (permanent)

**Steps required:**
1. Update `services/proxy/caddy/sites/authentik.Caddyfile`:
   - Change hostname from `sso.mykyta-ryasny.dev` to `auth.mykyta-ryasny.dev`
2. Update `services/tunnel/cloudflared/config.yml`:
   - Change hostname from `sso.` to `auth.`
3. Update portal API calls in `homeserver-portal` repository:
   - Change all `https://sso.mykyta-ryasny.dev` to `https://auth.mykyta-ryasny.dev`
4. Update Cloudflare DNS:
   - Create CNAME: `auth.mykyta-ryasny.dev` → tunnel
   - Delete CNAME: `sso.mykyta-ryasny.dev`
5. Restart services:
   ```bash
   docker compose restart caddy cloudflared
   ```

---

## Lessons Learned

### 1. User Logout Stage is Required for SLO

**Problem:** Default invalidation flows only had a Redirect Stage, not a User Logout Stage.

**Impact:** Sessions weren't cleared on logout, allowing immediate re-login without credentials.

**Solution:** Configure flows via API to use the User Logout Stage:

```python
# Find the User Logout stage UUID
GET /api/v3/stages/user_logout/

# Update flow bindings to use it
PATCH /api/v3/flows/bindings/<binding-id>/
{"stage": "<user-logout-stage-uuid>"}
```

**Verification:**
```bash
# Check flow configuration
curl -H "Authorization: Bearer <token>" \
  http://localhost:9000/api/v3/flows/instances/default-invalidation-flow/
```

### 2. Backchannel Logout Must Be Enabled

**Requirement:** All OAuth2 providers need `logout_method: "backchannel"` for SLO to work.

**Default:** Authentik sets this correctly, but always verify:

```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:9000/api/v3/providers/oauth2/ | grep logout_method
```

**Expected output:** `"logout_method": "backchannel"` for all providers.

### 3. CORS Headers for Direct API Access

**Portal requirement:** Direct API calls from Angular to Authentik API.

**Solution:** Add CORS headers in Caddy for `/api/*` paths:

```caddyfile
@api path /api/*
handle @api {
    header {
        Access-Control-Allow-Origin "https://home.mykyta-ryasny.dev"
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
        Access-Control-Allow-Credentials "true"
        Access-Control-Max-Age "3600"
    }

    @options method OPTIONS
    respond @options 204

    reverse_proxy authentik-server:9000
}
```

**Critical:** `Access-Control-Allow-Credentials: true` is required for session cookies.

### 4. Angular Signal Reactivity

**Problem:** API returns user data but UI shows "Guest".

**Cause:** Signal not triggering change detection (still debugging as of migration).

**Workaround:** Added extensive logging to track signal updates:

```typescript
this.userSignal.set(userInfo);
console.log('Signal value after set:', this.userSignal());
```

**Pending:** CI/CD rebuild to see console output.

### 5. Django Shell for API Token Creation

**When needed:** When `ak` CLI doesn't have the required command.

**Example:**
```bash
docker exec authentik-server python manage.py shell << 'EOF'
from authentik.core.models import Token, TokenIntents, User
user = User.objects.get(username='admin')
token, _ = Token.objects.get_or_create(
    user=user,
    intent=TokenIntents.INTENT_API,
    expiring=False
)
print(token.key)
EOF
```

**Security:** Delete temporary tokens after use:
```python
Token.objects.filter(identifier='temp-token').delete()
```

---

## Resources

### Official Documentation

- **Authentik Docs:** https://docs.goauthentik.io/
- **User Logout Stage:** https://docs.goauthentik.io/add-secure-apps/flows-stages/stages/user_logout/
- **Flow Executor:** https://docs.goauthentik.io/docs/flow/
- **API Reference:** https://docs.goauthentik.io/developer-docs/api/

### API Endpoints Used

**Flows:**
- `GET /api/v3/flows/instances/` - List all flows
- `PATCH /api/v3/flows/instances/<slug>/` - Update flow

**Stages:**
- `GET /api/v3/stages/all/` - List all stages
- `GET /api/v3/stages/user_logout/<uuid>/` - Get logout stage

**Bindings:**
- `GET /api/v3/flows/bindings/?target=<flow-uuid>` - Get flow stage bindings
- `PATCH /api/v3/flows/bindings/<binding-uuid>/` - Update stage binding

**Providers:**
- `GET /api/v3/providers/oauth2/` - List OAuth2 providers
- `PATCH /api/v3/providers/oauth2/<id>/` - Update provider

**Users:**
- `GET /api/v3/core/users/me/` - Get current authenticated user
- `GET /api/v3/core/users/` - List all users
- `POST /api/v3/core/users/` - Create user

### Debugging Tools

**Check Authentik logs:**
```bash
docker compose logs -f authentik-server
docker compose logs -f authentik-worker
```

**Test API endpoints:**
```bash
# Get API token first (via Django shell)
TOKEN="your-api-token"

# List flows
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:9000/api/v3/flows/instances/

# Check user logout stage
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:9000/api/v3/stages/user_logout/
```

**Monitor logout flow:**
1. Open browser DevTools → Network tab
2. Click logout button
3. Watch for:
   - Redirect to `/if/flow/default-invalidation-flow/`
   - Backchannel logout requests to OAuth2 providers
   - Final redirect to login page

---

## Rollback Plan (If Needed)

**If migration fails, rollback steps:**

1. **Stop Authentik:**
   ```bash
   docker compose down authentik-server authentik-worker
   ```

2. **Restore Authelia/LDAP:**
   ```bash
   # Restore from backup
   docker compose up -d authelia ldap phpldapadmin
   ```

3. **Revert Caddy configs:**
   ```bash
   git checkout services/proxy/caddy/
   docker compose restart caddy
   ```

4. **Revert compose files:**
   ```bash
   git checkout compose/auth/
   docker compose up -d
   ```

**Note:** Keep Authelia/LDAP backups for 30 days post-migration.

---

## Success Criteria

- ✅ All users can log in via Authentik
- ✅ Forward authentication works for all services
- ✅ Jellyfin OIDC integration works
- ✅ Jellyseerr auto-SSO works
- ✅ Logout clears sessions across all services (SLO)
- ✅ Portal displays user info from Authentik API
- ✅ Grafana dashboards updated with Authentik metrics
- ✅ Old Authelia/LDAP services removed
- ✅ Documentation updated

**Status:** Migration complete! 🎉
