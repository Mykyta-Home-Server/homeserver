---
title: Scripts Reference
description: Automation scripts for maintenance and operations
---

Overview of automation scripts in `/opt/homeserver/scripts/`.

## Active Scripts

### backup.sh
Full system backup with Docker-aware logging.

```bash
./scripts/backup.sh
```

Creates timestamped backup in `/backups/`.

### jellyfin-cleanup.py
Removes orphaned media from Jellyfin that no longer exists on disk.

```bash
python3 scripts/jellyfin-cleanup.py
```

Runs automatically via maintenance-cron every 5 minutes.

### media-cleanup.py
General media file cleanup and organization.

```bash
python3 scripts/media-cleanup.py
```

### sync-arr-profiles.py
Syncs quality profiles between Radarr and Sonarr.

```bash
python3 scripts/sync-arr-profiles.py
```

### radarr-delete-torrent.sh
Automatically deletes torrent from qBittorrent when movie is deleted from Radarr.

Triggered via Radarr Connect (custom script notification).

```bash
# Radarr Connect configuration:
# Path: /scripts/radarr-delete-torrent.sh
# Event: On Movie Delete
```

## Maintenance Cron

The `maintenance-cron` container runs scheduled tasks:

```crontab
*/5 * * * * /scripts/jellyfin-cleanup.py
0 3 * * * /scripts/backup.sh
```

### Check Cron Logs

```bash
docker logs maintenance-cron --tail 50
```

## Creating New Scripts

1. Create script in `/opt/homeserver/scripts/`
2. Make executable: `chmod +x scripts/myscript.sh`
3. Add to crontab if scheduled
4. Mount in container if needed

### Example Script

```bash
#!/bin/bash
# scripts/example.sh

LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

log() {
    echo "$LOG_PREFIX $1"
}

log "Starting task..."
# Your logic here
log "Task completed"
```
