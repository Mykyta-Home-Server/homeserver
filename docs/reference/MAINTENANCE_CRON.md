# Maintenance Cron - Quick Reference

**Container:** `maintenance-cron`
**Profile:** `maintenance`, `all`
**Purpose:** Dockerized scheduled tasks with Grafana logging

---

## Quick Commands

```bash
# View logs (real-time)
docker logs -f maintenance-cron

# View logs (last 100 lines)
docker logs --tail 100 maintenance-cron

# Restart cron
docker compose restart maintenance-cron

# Check status
docker compose ps | grep maintenance-cron
```

---

## Cron Schedule

| Time | Script | Purpose |
|------|--------|---------|
| Daily 3 AM | `/scripts/backup.sh` | Full system backup |
| Every 5 min | `jellyfin-cleanup.py` | Remove orphaned media |
| Daily 4 AM | `jellyseerr-cleanup.py` | Clean request database |

**Location:** `/opt/homeserver/services/maintenance/cron/crontab`

---

## Viewing Logs in Grafana

### 1. Access Grafana
https://monitor.mykyta-ryasny.dev

### 2. Explore → Loki

### 3. Useful Queries

**All cron activity:**
```logql
{container_name="maintenance-cron"}
```

**Just backup logs:**
```logql
{container_name="maintenance-cron"} |= "backup"
```

**Jellyfin cleanup:**
```logql
{container_name="maintenance-cron"} |= "Jellyfin"
```

**Errors only:**
```logql
{container_name="maintenance-cron"} |~ "(?i)error|failed"
```

**Last hour:**
```logql
{container_name="maintenance-cron"} [1h]
```

---

## Editing Cron Schedule

**1. Edit crontab:**
```bash
vim /opt/homeserver/services/maintenance/cron/crontab
```

**2. Apply changes:**
```bash
docker compose restart maintenance-cron
```

**3. Verify:**
```bash
docker logs maintenance-cron
```

---

## Cron Syntax Quick Reference

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday=0)
│ │ │ │ │
│ │ │ │ │
* * * * * command
```

**Examples:**
- `0 3 * * *` - Daily at 3 AM
- `*/5 * * * *` - Every 5 minutes
- `0 */4 * * *` - Every 4 hours
- `0 9 * * 1` - Every Monday at 9 AM

---

## Environment Variables

Container has access to:
- `TZ=Europe/Madrid` - Timezone
- `JELLYFIN_API_KEY` - From `.env` file
- `JELLYFIN_URL=http://jellyfin:8096`

---

## Troubleshooting

### Cron not running

**Check if container is up:**
```bash
docker ps | grep maintenance-cron
```

**Check logs for errors:**
```bash
docker logs maintenance-cron
```

### Script failing

**Run script manually:**
```bash
docker exec maintenance-cron /scripts/backup.sh
```

**Check script exists:**
```bash
docker exec maintenance-cron ls -la /scripts/
```

### Missing API key

**Check environment:**
```bash
docker exec maintenance-cron env | grep JELLYFIN
```

**Add to .env:**
```bash
echo "JELLYFIN_API_KEY=your-key" >> /opt/homeserver/.env
docker compose restart maintenance-cron
```

---

## Adding New Cron Jobs

**1. Edit crontab:**
```bash
vim /opt/homeserver/services/maintenance/cron/crontab
```

**2. Add new job:**
```cron
# Description of what it does
0 2 * * * /scripts/my-new-script.sh 2>&1
```

**3. Create script (if needed):**
```bash
vim /opt/homeserver/scripts/my-new-script.sh
chmod +x /opt/homeserver/scripts/my-new-script.sh
```

**4. Restart:**
```bash
docker compose restart maintenance-cron
```

---

## Benefits Over Host Cron

✅ **Logs in Grafana** - Query, filter, alert
✅ **Docker-managed** - Auto-restart, health checks
✅ **Isolated** - Container-based execution
✅ **Consistent** - Same patterns as other services
✅ **Portable** - Docker Compose handles everything

---

**Last Updated:** 2025-11-27
