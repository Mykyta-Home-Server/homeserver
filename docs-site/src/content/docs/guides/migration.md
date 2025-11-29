---
title: Migration Guide
description: Migrate from VM to physical server
---

Guide for migrating the home server from Hyper-V VM to physical hardware.

## Pre-Migration Checklist

- [ ] Backup all data
- [ ] Document current configuration
- [ ] Test restore procedure
- [ ] Prepare physical hardware

## Backup

```bash
# Full backup
cd /opt/homeserver
./scripts/backup.sh

# Verify backup
ls -la /backups/
```

## What to Migrate

### Must Copy
- `/opt/homeserver/` (entire directory)
- Docker volumes (included in backup)

### Don't Copy
- Container images (will be pulled fresh)
- Logs (will be regenerated)

## Migration Steps

1. **Install Ubuntu Server 22.04** on physical hardware

2. **Install Docker**
   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker $USER
   ```

3. **Restore backup**
   ```bash
   sudo mkdir -p /opt/homeserver
   sudo tar -xzf backup.tar.gz -C /opt
   sudo chown -R $USER:$USER /opt/homeserver
   ```

4. **Update network configuration**
   - Update IP addresses if changed
   - Update Cloudflare DNS if needed

5. **Start services**
   ```bash
   cd /opt/homeserver
   docker compose up -d
   ```

6. **Verify**
   ```bash
   docker compose ps
   curl https://mykyta-ryasny.dev
   ```

## Post-Migration

- Update SSH keys if changed
- Test all services
- Update monitoring dashboards
- Verify backups work on new hardware
