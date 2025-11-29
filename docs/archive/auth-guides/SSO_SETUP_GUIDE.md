# SSO Setup Guide - Quick Reference

**Last Updated:** 2025-11-25

---

## Overview

This guide provides step-by-step instructions to complete the SSO (Single Sign-On) configuration for all home server services using Authelia.

---

## Current Status

| Service | Auto-Login | Configuration Required | Notes |
|---------|-----------|------------------------|-------|
| **qBittorrent** | ✅ Working | None | Fully automated via network whitelist |
| **Jellyseerr** | ⚙️ Manual Setup | Enable proxy auth in UI | One-time configuration |
| **Uptime Kuma** | ⚙️ Manual Setup | Disable auth in UI | One-time configuration |
| **Jellyfin** | ❌ No Support | Accept double login | Technical limitation |
| **Sonarr/Radarr/Prowlarr** | N/A | None needed | Authelia protection sufficient |
| **Grafana** | N/A | None needed | Authelia protection sufficient |

---

## Configuration Steps

### ✅ qBittorrent (Already Configured)

**Status:** Fully working, no action needed

**How it works:**
- qBittorrent trusts requests from Docker networks (172.18.0.0/16, 172.19.0.0/16)
- Bypasses login for whitelisted subnets
- Authelia → qBittorrent (no qBittorrent login)

---

### ⚙️ Jellyseerr - Enable Proxy Authentication

**Time Required:** 2 minutes

**Steps:**

1. **Access Jellyseerr**
   - Go to https://requests.mykyta-ryasny.dev
   - Log in with Authelia
   - Log in with your Jellyseerr credentials (last time!)

2. **Open Settings**
   - Click your **profile picture** (top right)
   - Select **Settings**

3. **Configure Proxy Support**
   - Navigate to **General** tab
   - Scroll down to **"Proxy Support"** section
   - Toggle **"Enable Proxy Support"** to ON

4. **Set Headers**
   - **Authentication Header:** `Remote-User`
   - **Email Header:** `Remote-Email`

5. **Save and Test**
   - Click **Save Changes**
   - Log out of Jellyseerr
   - Close browser/clear cookies
   - Visit https://requests.mykyta-ryasny.dev again
   - ✅ Should automatically log you in using Authelia

**Result:** Authelia → Jellyseerr (auto-login) ✅

---

### ⚙️ Uptime Kuma - Disable Authentication

**Time Required:** 1 minute

**Steps:**

1. **Access Uptime Kuma**
   - Go to https://uptime.mykyta-ryasny.dev
   - Log in with Authelia
   - Log in with Uptime Kuma credentials

2. **Open Settings**
   - Click **Settings** (gear icon, bottom left sidebar)

3. **Navigate to Security**
   - Select **Security** tab

4. **Disable Authentication**
   - Find **"Disable Authentication"** option
   - Toggle it to **ON**
   - Confirm the warning dialog

5. **Test**
   - Close browser/clear cookies
   - Visit https://uptime.mykyta-ryasny.dev
   - ✅ Should go directly to Uptime Kuma dashboard

**Result:** Authelia → Uptime Kuma (auto-login) ✅

**Security Note:** Authelia still protects access to Uptime Kuma - only authenticated users can reach it.

---

### ℹ️ Jellyfin - Accept Double Login

**Status:** No SSO support available

**Current Behavior:**
- Authelia → Jellyfin login page → Jellyfin

**Why This Is Okay:**
1. Authelia protects the streaming.mykyta-ryasny.dev URL
2. Only Authelia-authenticated users can reach Jellyfin
3. Jellyfin provides user-specific libraries and permissions
4. Different family members can have different Jellyfin access levels
5. Jellyfin mobile apps require their own authentication anyway

**Future Options (Advanced):**
- **LDAP Integration** - Complex, requires OpenLDAP setup
- **SSO Plugin** - May be available in Jellyfin plugin repository
- **Accept as-is** - Recommended for simplicity

**Result:** Authelia → Jellyfin login page (acceptable) ✅

---

## Logout Handling

### Problem
Logging out of individual services doesn't log you out of Authelia, so you automatically log back in when revisiting services.

### Solution: Log Out from Authelia

To properly log out of **all services**:

**Method 1: Via Authelia Portal**
1. Visit https://auth.mykyta-ryasny.dev
2. Click your **username** (top right)
3. Click **"Logout"**
4. ✅ You're now logged out of everything

**Method 2: Direct Logout URL**
- Bookmark this URL: https://auth.mykyta-ryasny.dev/logout
- Click it whenever you want to log out
- ✅ Instantly logs you out of all services

**Method 3: Add to Home Dashboard**
- Add a "Logout" button to your Angular portal
- Link it to `https://auth.mykyta-ryasny.dev/logout`
- One-click logout from anywhere

---

## Testing Your Configuration

### Test qBittorrent
1. Open **incognito/private window**
2. Go to https://torrent.mykyta-ryasny.dev
3. Log in with Authelia credentials
4. ✅ **Should see qBittorrent directly** (no qBittorrent login)

### Test Jellyseerr (after configuration)
1. Open **incognito/private window**
2. Go to https://requests.mykyta-ryasny.dev
3. Log in with Authelia credentials
4. ✅ **Should see Jellyseerr directly** (no Jellyseerr login)

### Test Uptime Kuma (after configuration)
1. Open **incognito/private window**
2. Go to https://uptime.mykyta-ryasny.dev
3. Log in with Authelia credentials
4. ✅ **Should see Uptime Kuma directly** (no Uptime Kuma login)

### Test Jellyfin
1. Open **incognito/private window**
2. Go to https://streaming.mykyta-ryasny.dev
3. Log in with Authelia credentials
4. ✅ **Will see Jellyfin login page** (expected behavior)
5. Log in with Jellyfin credentials
6. ✅ Access Jellyfin

### Test Logout
1. Visit https://auth.mykyta-ryasny.dev/logout
2. ✅ Redirected to home dashboard
3. Try accessing any service
4. ✅ Should require Authelia login again

---

## Troubleshooting

### Jellyseerr Still Shows Login

**Check:**
1. Proxy support is enabled in Jellyseerr settings
2. Headers are spelled correctly:
   - `Remote-User` (case-sensitive)
   - `Remote-Email` (case-sensitive)
3. Clear browser cookies for `requests.mykyta-ryasny.dev`
4. Try in incognito mode

**Fix:**
```bash
# Restart Jellyseerr
docker compose --profile all restart jellyseerr
```

### Uptime Kuma Still Shows Login

**Check:**
1. "Disable Authentication" is toggled ON in Settings → Security
2. Clear browser cookies for `uptime.mykyta-ryasny.dev`

**Fix:**
```bash
# Restart Uptime Kuma
docker compose --profile all restart uptime-kuma
```

### qBittorrent Shows Login Again

**Check configuration persisted:**
```bash
grep "WebUI" /opt/homeserver/services/media/qbittorrent/config/qBittorrent/qBittorrent.conf
```

**Should see:**
- `WebUI\BypassAuthenticationForWhitelist=true`
- `WebUI\AuthSubnetWhitelist=172.18.0.0/16, 172.19.0.0/16, 127.0.0.1`

**Fix if missing:**
```bash
# Stop qBittorrent
docker compose --profile all stop qbittorrent

# Update config
CONFIG_FILE="/opt/homeserver/services/media/qbittorrent/config/qBittorrent/qBittorrent.conf"
sed -i 's|WebUI\\AuthSubnetWhitelist=.*|WebUI\\AuthSubnetWhitelist=172.18.0.0/16, 172.19.0.0/16, 127.0.0.1|' "$CONFIG_FILE"
sed -i 's|WebUI\\TrustedReverseProxiesList=.*|WebUI\\TrustedReverseProxiesList=172.18.0.0/16, 172.19.0.0/16|' "$CONFIG_FILE"
grep -q "BypassAuthenticationForWhitelist" "$CONFIG_FILE" || sed -i '/WebUI\\AuthSubnetWhitelistEnabled=true/a WebUI\\BypassAuthenticationForWhitelist=true' "$CONFIG_FILE"

# Start qBittorrent
docker compose --profile all start qbittorrent
```

---

## Summary

After completing these steps, your SSO experience will be:

1. **Log in once** to Authelia
2. **Access all services** without additional logins (except Jellyfin)
3. **Log out once** from Authelia to log out everywhere

**Time to Complete:** ~5 minutes total
- Jellyseerr: 2 minutes
- Uptime Kuma: 1 minute
- Testing: 2 minutes

---

## Next Steps

1. ✅ Complete Jellyseerr configuration (2 min)
2. ✅ Complete Uptime Kuma configuration (1 min)
3. ✅ Test all services in incognito mode
4. ✅ Bookmark https://auth.mykyta-ryasny.dev/logout
5. ✅ Add logout button to home dashboard (optional)

---

## Related Files

- [Caddy Media Configuration](../services/proxy/caddy/sites/media.Caddyfile) - qBittorrent, Jellyseerr proxy settings
- [Caddy Uptime Kuma Configuration](../services/proxy/caddy/sites/uptime-kuma.Caddyfile) - Uptime Kuma proxy settings
- [Authelia Configuration](../services/auth/authelia/configuration.yml) - Access control rules
- [qBittorrent Config](../services/media/qbittorrent/config/qBittorrent/qBittorrent.conf) - Bypass authentication settings

---

**Questions or Issues?** Check the troubleshooting section above or review Authelia logs:
```bash
docker compose logs authelia --tail=100
```