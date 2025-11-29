# Scripts Reference

Documentation for all scripts in `/opt/homeserver/scripts/`.

## 📋 Overview

All scripts are located in `/opt/homeserver/scripts/` and are categorized by purpose:
- **Backup & Restore** - Data protection
- **Maintenance** - Automated cleanup and optimization
- **Diagnostic** - Troubleshooting and inspection tools

---

## 🔒 Backup & Restore

### backup.sh

**Purpose:** Automated backup of Docker volumes, configs, and secrets

**Schedule:** Daily at 3 AM (via cron)

**What it backs up:**
- Database dumps (PostgreSQL, Redis)
- Service configurations
- Docker Compose files
- Scripts and documentation
- Secrets (encrypted)

**What it excludes:**
- Large media files (`/data/media/`)
- Container caches
- Temporary files

**Usage:**
```bash
# Manual backup
/opt/homeserver/scripts/backup.sh

# Check backup logs
tail -f /opt/homeserver/backups/backup.log

# List backups
ls -lh /opt/homeserver/backups/
```

**Retention:** 30 days (automatically deletes old backups)

**Backup Location:** `/opt/homeserver/backups/homeserver_backup_YYYYMMDD_HHMMSS.tar.gz`

---

### restore-test.sh

**Purpose:** Verify backup integrity and test restoration process

**Usage:**
```bash
# Test latest backup
/opt/homeserver/scripts/restore-test.sh

# Test specific backup
/opt/homeserver/scripts/restore-test.sh /path/to/backup.tar.gz
```

**What it does:**
1. Creates temporary test directory
2. Extracts backup
3. Verifies file integrity
4. Checks database dumps
5. Cleans up test directory

**⚠️ Warning:** Always test backups before you need them!

---

## 🧹 Maintenance Scripts

### jellyfin-cleanup.py

**Purpose:** Removes items from Jellyfin database that no longer exist on disk

**Schedule:** Every 5 minutes (via cron wrapper)

**Why it's needed:** When files are deleted outside Jellyfin, orphaned database entries remain

**Requirements:**
- Jellyfin API key (set as environment variable)

**Manual Usage:**
```bash
# Set API key
export JELLYFIN_API_KEY='your-api-key-here'

# Run cleanup
python3 /opt/homeserver/scripts/jellyfin-cleanup.py
```

**To get API key:**
1. Go to https://streaming.mykyta-ryasny.dev
2. Login as admin → Dashboard → Advanced → API Keys
3. Click "+ New API Key"
4. Name: "Cleanup Script"
5. Copy the key

---

### jellyfin-cleanup-cron.sh

**Purpose:** Wrapper script for automated Jellyfin cleanup

**Schedule:** Every 5 minutes (cron job)

**Cron entry:**
```cron
*/5 * * * * /opt/homeserver/scripts/jellyfin-cleanup-cron.sh
```

**What it does:**
1. Sources API key from environment/config
2. Runs `jellyfin-cleanup.py`
3. Logs output

---

### run-jellyfin-cleanup.sh

**Purpose:** Manual execution wrapper for Jellyfin cleanup

**Usage:**
```bash
/opt/homeserver/scripts/run-jellyfin-cleanup.sh
```

Easier than remembering to set environment variables.

---

### jellyseerr-cleanup.py

**Purpose:** Cleans up Jellyseerr database (removes old requests, etc.)

**Usage:**
```bash
python3 /opt/homeserver/scripts/jellyseerr-cleanup.py
```

**Manual run wrapper:**
```bash
/opt/homeserver/scripts/run-jellyseerr-cleanup.sh
```

---

### sync-arr-profiles.py

**Purpose:** Sync custom formats from Radarr to Sonarr

**Use case:** You've configured custom formats (e.g., H.264 preference) in Radarr and want them in Sonarr

**Requirements:**
- Radarr API key
- Sonarr API key

**Usage:**
```bash
# Set API keys
export RADARR_API_KEY='your-radarr-key'
export SONARR_API_KEY='your-sonarr-key'

# Run sync
python3 /opt/homeserver/scripts/sync-arr-profiles.py
```

**To find API keys:**
- **Radarr:** Settings → General → Security → API Key
- **Sonarr:** Settings → General → Security → API Key

**Manual run wrapper:**
```bash
# Wrapper script handles environment setup
/opt/homeserver/scripts/sync-arr-profiles.sh
```

**⚠️ Security Note:** This script previously had hardcoded API keys. This has been fixed to use environment variables. Never commit API keys!

---

## 🔍 Diagnostic Tools

### ldap-inspect.sh

**Purpose:** Inspect LDAP directory structure and users

**Usage:**
```bash
# View all users
/opt/homeserver/scripts/ldap-inspect.sh

# View specific DN
/opt/homeserver/scripts/ldap-inspect.sh "cn=admin,dc=mykyta-ryasny,dc=dev"
```

**What it shows:**
- LDAP directory tree
- User accounts
- Group memberships
- Configuration details

**When to use:**
- Debugging authentication issues
- Verifying user creation
- Checking group assignments

---

### init-ldap.sh

**Purpose:** Initialize LDAP with default structure and users

**⚠️ One-time use:** This script was used during initial LDAP setup

**Usage:**
```bash
/opt/homeserver/scripts/init-ldap.sh
```

**What it does:**
1. Creates organizational units (OUs)
2. Sets up default groups
3. Creates initial admin user
4. Configures access controls

**Note:** Keep for reference but typically not needed after initial setup

---

### setup-log-rotation.sh

**Purpose:** Configure log rotation for Docker and services

**⚠️ One-time use:** Run during initial setup or after significant changes

**Usage:**
```bash
/opt/homeserver/scripts/setup-log-rotation.sh
```

**What it configures:**
- Docker container log rotation
- Caddy log rotation
- Grafana log rotation
- System log retention

---

## 📅 Cron Schedule

Current automated scripts:

| Script | Schedule | Description |
|--------|----------|-------------|
| `backup.sh` | Daily at 3 AM | Full system backup |
| `jellyfin-cleanup-cron.sh` | Every 5 minutes | Clean orphaned media |

**View cron jobs:**
```bash
crontab -l
```

**Edit cron jobs:**
```bash
crontab -e
```

---

## 🛠️ Modifying Scripts

### Best Practices

1. **Test changes locally first**
2. **Keep backups** of working scripts
3. **Document changes** in script headers
4. **Use environment variables** for secrets (never hardcode!)
5. **Check exit codes** and handle errors
6. **Add logging** for troubleshooting

### Example: Adding a new maintenance script

```bash
#!/bin/bash
# ============================================================================
# My New Script
# ============================================================================
# Purpose: Brief description
# Schedule: When it runs (if automated)
# ============================================================================

set -euo pipefail  # Exit on error, undefined var, or pipe failure

# Configuration
SCRIPT_NAME="my-script"
LOG_FILE="/opt/homeserver/logs/${SCRIPT_NAME}.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting ${SCRIPT_NAME}"

# Your script logic here

log "${SCRIPT_NAME} completed successfully"
```

---

## 🔐 Security Considerations

### Environment Variables

**✅ DO:**
- Use environment variables for API keys, passwords, secrets
- Validate that required variables are set
- Use `.env` files (gitignored) for local development

**❌ DON'T:**
- Hardcode credentials in scripts
- Commit `.env` files to git
- Echo secrets to logs

### Example: Checking required variables

```bash
if [ -z "${API_KEY:-}" ]; then
    echo "ERROR: API_KEY environment variable not set"
    echo "Usage: export API_KEY='your-key' && $0"
    exit 1
fi
```

---

## 📁 Script Locations

```
/opt/homeserver/scripts/
├── backup.sh                      # Daily backup
├── restore-test.sh                # Backup verification
├── jellyfin-cleanup.py            # Media cleanup
├── jellyfin-cleanup-cron.sh       # Cron wrapper
├── run-jellyfin-cleanup.sh        # Manual wrapper
├── jellyseerr-cleanup.py          # Request cleanup
├── run-jellyseerr-cleanup.sh      # Manual wrapper
├── sync-arr-profiles.py           # Custom format sync
├── sync-arr-profiles.sh           # Sync wrapper
├── ldap-inspect.sh                # LDAP diagnostics
├── init-ldap.sh                   # LDAP initialization
└── setup-log-rotation.sh          # Log rotation setup
```

---

## 🆘 Troubleshooting

### Script won't run

**Check permissions:**
```bash
ls -la /opt/homeserver/scripts/
chmod +x /opt/homeserver/scripts/script-name.sh
```

### Python scripts fail

**Check Python version:**
```bash
python3 --version  # Should be 3.8+
```

**Install dependencies:**
```bash
pip3 install requests  # Most scripts need this
```

### Cron job not running

**Check cron is running:**
```bash
systemctl status cron
```

**View cron logs:**
```bash
grep CRON /var/log/syslog | tail -20
```

**Test cron command manually:**
```bash
# Run the exact command from crontab
/opt/homeserver/scripts/backup.sh
```

---

**Last Updated:** 2025-11-27
