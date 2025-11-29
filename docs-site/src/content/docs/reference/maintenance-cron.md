---
title: Maintenance Cron
description: Dockerized cron jobs for automated maintenance
---

Automated maintenance tasks running in a Docker container.

## Overview

The `maintenance-cron` container is an Alpine-based image with:
- Python 3
- Docker CLI (for container management)
- Cron daemon

## Current Schedule

| Schedule | Task | Description |
|----------|------|-------------|
| `*/5 * * * *` | jellyfin-cleanup.py | Remove orphaned media |
| `0 3 * * *` | backup.sh | Daily backup at 3 AM |

## Configuration

Crontab file: `/opt/homeserver/services/maintenance/cron/crontab`

```crontab
# Cleanup orphaned Jellyfin media every 5 minutes
*/5 * * * * /scripts/jellyfin-cleanup.py >> /proc/1/fd/1 2>&1

# Daily backup at 3 AM
0 3 * * * /scripts/backup.sh >> /proc/1/fd/1 2>&1
```

## Viewing Logs

```bash
# Follow cron logs
docker logs -f maintenance-cron

# Last 50 lines
docker logs maintenance-cron --tail 50
```

## Adding New Jobs

1. Edit crontab:
   ```bash
   nano services/maintenance/cron/crontab
   ```

2. Add your job:
   ```crontab
   0 * * * * /scripts/my-hourly-task.sh >> /proc/1/fd/1 2>&1
   ```

3. Restart container:
   ```bash
   docker compose restart maintenance-cron
   ```

## Cron Syntax

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6)
│ │ │ │ │
* * * * * command
```

### Examples

```crontab
*/15 * * * *    # Every 15 minutes
0 * * * *       # Every hour
0 0 * * *       # Daily at midnight
0 0 * * 0       # Weekly on Sunday
0 0 1 * *       # Monthly on 1st
```

## Manual Execution

Run a task immediately:

```bash
docker exec maintenance-cron /scripts/jellyfin-cleanup.py
```
