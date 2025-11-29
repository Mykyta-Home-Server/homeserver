# Grafana Loki Monitoring Stack - Complete Guide

**Last Updated:** 2025-11-24

---

## 📋 Table of Contents

1. [Overview & Architecture](#overview)
2. [Key Concepts](#key-concepts-explained)
3. [Configuration Files](#configuration-files-explained)
4. [Deployment Steps](#deployment-steps)
5. [Verification & Testing](#verification--testing)
6. [Common Queries](#common-queries-logql-examples)
7. [Troubleshooting](#troubleshooting)
8. [Resource Usage](#resource-usage)
9. [Next Steps](#next-steps)
10. [Appendix: LogQL Quick Reference](#appendix-logql-quick-reference)

---

## Overview

This guide walks you through deploying and understanding the Grafana Loki logging stack for your home server.

**What you're building:**
- **Promtail**: Collects logs from all Docker containers
- **Loki**: Stores and indexes logs efficiently
- **Grafana**: Visualizes logs with beautiful dashboards

**Why this stack:**
- Centralized logging (all container logs in one place)
- Efficient storage (label-based indexing, not full-text)
- Powerful querying (LogQL query language)
- Production-grade (same stack used by companies worldwide)

---

## Architecture Deep Dive

### The Flow of a Log Line

```
1. Application Event
   ↓
   Your code: print("Error: Database timeout")

2. Docker Captures
   ↓
   Written to: /var/lib/docker/containers/<id>/<id>-json.log
   As JSON: {"log":"Error: Database timeout\n","stream":"stderr","time":"2024-..."}

3. Promtail Detects
   ↓
   - Watches file with inotify (Linux file monitoring)
   - Reads new line
   - Parses JSON
   - Extracts Docker metadata (container name, compose service, etc.)
   - Parses log line (detects "Error" → adds level="error" label)
   - Creates labeled log entry

4. Promtail Ships to Loki
   ↓
   HTTP POST to http://loki:3100/loki/api/v1/push
   With labels: {container="jellyfin", level="error", ...}

5. Loki Processes
   ↓
   - Determines stream (unique label combination)
   - Adds to chunk (compressed block of logs)
   - Writes to WAL (Write-Ahead Log) for durability
   - Eventually flushes chunk to disk: /loki/chunks/
   - Updates index: /loki/index/

6. You Query via Grafana
   ↓
   - Open https://monitor.mykyta-ryasny.dev
   - Run LogQL query: {container="jellyfin", level="error"}
   - Grafana → Loki API
   - Loki looks up index → finds chunks → decompresses → filters → returns
   - Grafana displays results
```

---

## Key Concepts Explained

### 1. Labels vs Full-Text Search

**Traditional logging (Elasticsearch):**
```
Index every word in every log:
"Error: Database timeout"
  → Index: "Error" → [log1, log5, log9]
  → Index: "Database" → [log1, log3, log8]
  → Index: "timeout" → [log1, log12]

Result: Massive index (10GB logs = 2GB index)
```

**Loki's approach:**
```
Index only labels:
{container="jellyfin", level="error"}
  → Points to chunks containing these logs

Then grep through just those chunks for specific text.

Result: Tiny index (10GB logs = 10MB index)
```

**Why this works for containers:**
- Containers already have rich metadata (name, image, service)
- Most queries are "show me logs from X container" (label query)
- Full-text search across all logs is rare
- Trade-off: Label queries are fast, full-text is slightly slower (but still fast enough!)

### 2. Streams and Chunks

**Stream:**
A unique combination of labels.

Example streams:
```
Stream 1: {container="jellyfin", level="info", stream="stdout"}
Stream 2: {container="jellyfin", level="error", stream="stderr"}
Stream 3: {container="prowlarr", level="info", stream="stdout"}
```

Each stream is stored separately.

**Chunk:**
A compressed block of log lines from one stream.

```
Chunk lifecycle:
1. Loki receives logs → adds to current chunk (in memory)
2. Chunk reaches 1MB or 1 hour old → flush to disk
3. Compress with gzip (1MB → ~100KB)
4. Write to /loki/chunks/stream1_chunk123.gz
5. Update index: stream1 → chunk123 (lines 1-5000)
```

**Why chunks?**
- Compression (10x reduction)
- Efficient I/O (read one chunk = thousands of log lines)
- Time-based sharding (old chunks can be deleted for retention)

### 3. LogQL Query Language

LogQL is inspired by Prometheus PromQL, but for logs.

**Basic query structure:**
```
{label_selector} | filter | parser | aggregation
```

**Examples:**

Show all logs from Jellyfin:
```logql
{container="jellyfin"}
```

Filter for errors:
```logql
{container="jellyfin"} |= "error"
```

Exclude health checks:
```logql
{container="caddy"} != "GET /health"
```

Parse JSON logs:
```logql
{container="api"} | json | status_code="500"
```

Count errors per minute:
```logql
count_over_time({level="error"}[1m])
```

Top 10 containers by log volume:
```logql
topk(10, sum by (container) (count_over_time({container!=""}[1h])))
```

**Operators:**
- `|=` : Contains (grep)
- `!=` : Doesn't contain
- `|~ "regex"` : Regex match
- `!~ "regex"` : Regex doesn't match
- `| json` : Parse as JSON
- `| logfmt` : Parse as logfmt (key=value)
- `| line_format` : Reformat line

### 4. Cardinality (IMPORTANT!)

**Cardinality = Number of unique label combinations (streams)**

**Example of BAD cardinality:**
```
Labels: {container="jellyfin", user_id="12345", request_id="abc-def-ghi"}

If you have:
- 10 containers
- 1000 users
- 1 million requests

Cardinality = 10 × 1000 × 1,000,000 = 10 BILLION streams!
```

This will destroy Loki's performance.

**Good practice:**
```
Labels: {container="jellyfin", level="error"}

Cardinality = 10 containers × 5 levels = 50 streams
```

**Rule of thumb:**
- Keep label cardinality under 10,000 streams
- Don't use high-cardinality values as labels (user IDs, request IDs, IPs)
- Use labels for dimensions you want to filter/aggregate by
- Put high-cardinality data in the log line itself

---

## Configuration Files Explained

### Loki Config (`loki-config.yml`)

**Ingester:**
```yaml
chunk_idle_period: 1h  # Flush if no logs for 1 hour
max_chunk_age: 1h      # Flush after 1 hour regardless
```

Why? Balance between:
- Small chunks = more files, more overhead
- Large chunks = delayed queries (can't search until flushed)

**Schema:**
```yaml
schema: v11
store: boltdb-shipper
object_store: filesystem
```

- v11 = Latest schema version (optimized)
- boltdb-shipper = Index stored in BoltDB (embedded key-value database)
- filesystem = Chunks stored on local disk

**Retention:**
```yaml
retention_period: 720h  # 30 days
```

After 30 days, old chunks and indexes are deleted.

Calculate disk usage:
```
Daily log volume × 30 days × compression ratio

Example:
- 1GB/day raw logs
- 30 days retention
- 10x compression
= (1GB × 30) / 10 = 3GB disk usage
```

### Promtail Config (`promtail-config.yml`)

**Service Discovery:**
```yaml
docker_sd_configs:
  - host: unix:///var/run/docker.sock
```

Promtail watches Docker socket for:
- New containers starting
- Containers stopping
- Container metadata changes

**Relabeling (The Magic):**
```yaml
- source_labels: ['__meta_docker_container_name']
  regex: '/(.*)'
  target_label: 'container'
```

This extracts container name from Docker metadata:
```
Input: __meta_docker_container_name="/jellyfin"
Regex: /(.*) → captures "jellyfin"
Output: container="jellyfin"
```

**Pipeline Stages:**
```yaml
- json:  # Parse Docker JSON format
- labels:  # Extract fields as labels
- timestamp:  # Parse timestamp
- regex:  # Extract patterns (log levels)
```

Each log line goes through this pipeline:
1. Parse JSON (Docker format)
2. Extract labels (stdout/stderr, timestamp)
3. Detect log level (ERROR, WARN, INFO)
4. Output clean log line

### Grafana Provisioning

**Why provisioning?**

Without provisioning:
1. Start Grafana
2. Click "Add datasource"
3. Type Loki URL: http://loki:3100
4. Click "Save & Test"
5. Create dashboard manually

With provisioning:
1. Start Grafana
2. Everything is ready!

This is **Infrastructure as Code** - all configuration in files, reproducible.

**Datasource provisioning:**
```yaml
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
    isDefault: true
```

Grafana reads this on startup and auto-configures Loki.

**Dashboard provisioning:**
```json
{
  "panels": [
    {
      "type": "logs",
      "targets": [{
        "expr": "{container=\"$container\"}"
      }]
    }
  ]
}
```

Pre-built dashboard loaded automatically.

---

## Deployment Steps

### 1. Verify Files Created

```bash
# Check directory structure
ll services/monitoring/

# Expected output:
# drwxrwxr-x grafana/
# drwxrwxr-x loki/
# drwxrwxr-x promtail/

# Check configs exist
ll services/monitoring/loki/loki-config.yml
ll services/monitoring/promtail/promtail-config.yml
ll services/monitoring/grafana/grafana.ini
```

### 2. Set Permissions

```bash
# Grafana runs as user 472, needs write access to data directory
sudo chown -R 472:472 services/monitoring/grafana/data

# Loki needs write access for chunks and index
sudo chown -R 10001:10001 services/monitoring/loki/data

# Promtail needs to track positions
sudo chown -R 10001:10001 services/monitoring/promtail/positions
```

### 3. Add DNS Record

In Cloudflare dashboard:
```
Type: CNAME
Name: monitor
Target: 07fbc124-6f0e-40c5-b254-3a1bdd98cf3c.cfargotunnel.com
Proxy: Yes (orange cloud)
```

### 4. Start the Stack

```bash
# Start monitoring services
docker compose up -d loki promtail grafana

# Expected output:
# [+] Running 4/4
#  ✔ Network monitoring      Created
#  ✔ Container loki          Started
#  ✔ Container promtail      Started
#  ✔ Container grafana       Started

# Check status
docker compose ps

# Expected output:
# NAME       IMAGE                      STATUS
# loki       grafana/loki:2.9.3        Up (healthy)
# promtail   grafana/promtail:2.9.3    Up
# grafana    grafana/grafana:10.2.2    Up (healthy)
```

### 5. Restart Caddy (to load new config)

```bash
# Restart Caddy to pick up monitoring.Caddyfile
docker compose restart caddy

# Expected output:
# [+] Restarting 1/1
#  ✔ Container caddy  Started

# Check Caddy logs for monitoring site
docker logs caddy 2>&1 | grep monitor

# Expected output:
# ... monitor.mykyta-ryasny.dev
```

### 6. Restart Cloudflare Tunnel (to pick up new route)

```bash
# Restart tunnel to load updated config
docker compose restart cloudflared

# Expected output:
# [+] Restarting 1/1
#  ✔ Container cloudflared  Started

# Check tunnel logs
docker logs cloudflared 2>&1 | grep monitor

# Expected output:
# ... Registered tunnel connection ... monitor.mykyta-ryasny.dev
```

---

## Verification & Testing

### 1. Check Service Health

```bash
# Check all containers are healthy
docker compose ps

# Check Loki is ready
curl -s http://localhost:3100/ready
# Expected: "ready"

# Check Promtail is running
docker logs promtail --tail 50
# Expected: "Promtail started"

# Check Grafana is up
curl -s http://localhost:3000/api/health | jq
# Expected: {"database":"ok","version":"..."}
```

### 2. Verify Promtail is Collecting Logs

```bash
# Check Promtail discovered containers
curl -s http://localhost:9080/targets | jq '.activeTargets[] | {container:.labels.container, state:.health}'

# Expected output:
# {
#   "container": "jellyfin",
#   "state": "up"
# }
# {
#   "container": "prowlarr",
#   "state": "up"
# }
# ... (all your containers)
```

### 3. Query Loki Directly (Test LogQL)

```bash
# Get label values (which containers are being logged)
curl -s 'http://localhost:3100/loki/api/v1/label/container/values' | jq

# Expected:
# {
#   "status": "success",
#   "data": ["jellyfin", "prowlarr", "sonarr", "radarr", ...]
# }

# Query logs
curl -G -s 'http://localhost:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={container="jellyfin"}' \
  --data-urlencode 'limit=10' | jq '.data.result[0].values'

# Expected: Array of [timestamp, log line]
```

### 4. Access Grafana

```bash
# Open in browser:
https://monitor.mykyta-ryasny.dev

# Login credentials:
Username: admin
Password: admin

# First login: You'll be prompted to change password
```

### 5. Explore Logs in Grafana

1. **Go to Explore** (compass icon in left sidebar)
2. **Select Loki datasource** (should be pre-selected)
3. **Run queries:**
   ```
   {container="jellyfin"}
   ```
4. **Use label filters** (click labels in the UI)
5. **Try the dashboard:**
   - Go to Dashboards → Homeserver → Container Logs Dashboard
   - Select container from dropdown
   - Enter search term
   - See real-time logs!

---

## Common Queries (LogQL Examples)

### Show all logs from a container
```logql
{container="jellyfin"}
```

### Show only errors
```logql
{level="error"}
```

### Show errors from specific container
```logql
{container="jellyfin", level="error"}
```

### Search for specific text
```logql
{container="jellyfin"} |= "transcoding"
```

### Exclude health check logs
```logql
{container="caddy"} != "GET /health"
```

### Show last 5 minutes of errors
```logql
{level="error"} [5m]
```

### Count errors per minute
```logql
count_over_time({level="error"}[1m])
```

### Top 5 containers by log volume
```logql
topk(5, sum by (container) (count_over_time({container!=""}[1h])))
```

### Show only stderr logs
```logql
{stream="stderr"}
```

### Parse JSON logs and filter
```logql
{container="api"} | json | status_code="500"
```

---

## Troubleshooting

### Promtail not collecting logs

**Check:**
```bash
# Is Docker socket mounted?
docker exec promtail ls -la /var/run/docker.sock

# Can Promtail read it?
docker exec promtail ps aux | grep promtail

# Check Promtail logs for errors
docker logs promtail --tail 100
```

**Common issues:**
- Docker socket permissions
- Wrong path to Docker containers
- Promtail can't reach Loki

### Loki not storing logs

**Check:**
```bash
# Is Loki healthy?
curl http://localhost:3100/ready

# Check Loki logs
docker logs loki --tail 100

# Check if data is being written
ll services/monitoring/loki/data/
```

**Common issues:**
- Permissions on /loki directory
- Disk full
- Configuration errors

### Grafana can't connect to Loki

**Check:**
```bash
# Can Grafana reach Loki?
docker exec grafana curl -s http://loki:3100/ready

# Check Grafana logs
docker logs grafana --tail 100
```

**Common issues:**
- Wrong Loki URL in datasource
- Network connectivity
- Loki not started before Grafana

### No logs appearing in Grafana

**Troubleshooting steps:**
1. Check Promtail is collecting: `docker logs promtail`
2. Check Loki is receiving: `curl http://localhost:3100/loki/api/v1/label/container/values`
3. Check Grafana can query: Run `{container="jellyfin"}` in Explore
4. Check time range: Logs might be outside your selected time range

---

## Resource Usage

**Expected resource usage:**

Loki:
- CPU: 1-5% idle, 10-30% during queries
- RAM: 256-512MB
- Disk: ~100MB/day per GB of raw logs (with compression)

Promtail:
- CPU: 1-2%
- RAM: 64-128MB

Grafana:
- CPU: 1-5%
- RAM: 128-256MB

**Total stack overhead:**
- ~500MB RAM
- ~3GB disk for 30 days retention (assuming 1GB/day raw logs)
- Minimal CPU impact

---

## Next Steps

### 1. Change Grafana Password

```bash
# In Grafana UI:
# Click user icon → Change password
# Or reset via CLI:
docker exec grafana grafana-cli admin reset-admin-password newpassword
```

### 2. Create Custom Dashboards

In Grafana:
1. Go to Dashboards → New Dashboard
2. Add panel → Logs
3. Enter LogQL query
4. Save dashboard

### 3. Set Up Alerts (Future)

Grafana can alert you when specific log patterns appear:
- Email when errors spike
- Slack notification for critical logs
- Discord webhook for service failures

### 4. Add Metrics (Future Phase 6)

Complement logs with metrics:
- Prometheus for container metrics (CPU, RAM, disk)
- Node Exporter for system metrics
- cAdvisor for container stats
- Display both logs + metrics in unified dashboard

### 5. Optimize Retention

Adjust based on your needs:
```yaml
# In loki-config.yml:
retention_period: 720h  # 30 days (default)
# Or change to:
retention_period: 336h  # 14 days (save disk space)
retention_period: 2160h  # 90 days (more history)
```

---

## Learning Resources

- [Loki Official Docs](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)
- [Grafana Tutorials](https://grafana.com/tutorials/)
- [Best Practices for Loki](https://grafana.com/docs/loki/latest/best-practices/)

---

## Summary

You now have:
- ✅ Centralized log collection from all Docker containers
- ✅ Efficient log storage with 30-day retention
- ✅ Powerful LogQL query language
- ✅ Beautiful Grafana dashboards
- ✅ Real-time log streaming
- ✅ Infrastructure as Code (all config in Git)

**What you learned:**
- How Loki's label-based indexing works
- Why it's more efficient than full-text indexing
- How Promtail discovers and labels logs
- How chunks and streams work
- LogQL query syntax
- Grafana provisioning

This is a production-grade logging stack that will scale with your homeserver!

---

# Appendix: LogQL Quick Reference

## Basic Syntax

```
{label_selector} | filter | parser | formatter | aggregation
```

## Label Selectors

```logql
{container="jellyfin"}                    # Exact match
{container=~"jelly.*"}                    # Regex match
{container!="caddy"}                      # Not equal
{container=~"jelly.*", level="error"}     # Multiple labels (AND)
{container="jellyfin"} or {container="plex"}  # OR operator
```

## Line Filters

```logql
{container="jellyfin"} |= "error"         # Contains (case-sensitive)
{container="jellyfin"} != "health"        # Doesn't contain
{container="jellyfin"} |~ "error|warn"    # Regex match
{container="jellyfin"} !~ "debug|trace"   # Regex doesn't match
```

## Parsers

```logql
{container="api"} | json                   # Parse as JSON
{container="api"} | logfmt                 # Parse as key=value
{container="api"} | pattern "<ip> <status>"  # Custom pattern
{container="api"} | regexp "(?P<code>[0-9]{3})"  # Regex groups
```

## Label Filters (after parsing)

```logql
{container="api"} | json | status_code="500"
{container="api"} | json | latency > 1000
{container="api"} | json | method != "GET"
{container="api"} | json | user_id =~ "admin.*"
```

## Formatting

```logql
{container="api"} | line_format "{{.ip}} - {{.method}}"
{container="api"} | json | line_format "Status: {{.status}}"
```

## Aggregations

```logql
count_over_time({level="error"}[5m])
rate({container="jellyfin"}[1m])
sum by (container) (count_over_time({container!=""}[5m]))
topk(10, count_over_time({level="error"}[1h]))
```

## Time Ranges

```logql
{container="jellyfin"}[5m]     # Last 5 minutes
{container="jellyfin"}[1h]     # Last 1 hour
{container="jellyfin"}[1d]     # Last 1 day
```

## Common Query Patterns

### See all logs from a service
```logql
{compose_service="jellyfin"}
```

### Find errors in the last hour
```logql
{level="error"} [1h]
```

### Search across all containers
```logql
{container!=""} |= "database timeout"
```

### Errors per minute
```logql
count_over_time({level="error"}[1m])
```

### Top 5 noisiest containers
```logql
topk(5, sum by (container) (count_over_time({container!=""}[1h])))
```

### Slow API requests (>1s)
```logql
{container="api"} | json | duration > 1
```

### HTTP 5xx errors
```logql
{container="api"} | json | status_code=~"5.."
```

### Exclude health checks
```logql
{container="caddy"} != "/health" != "/metrics"
```

## Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `|=` | Contains | `|= "error"` |
| `!=` | Doesn't contain | `!= "debug"` |
| `|~` | Regex match | `|~ "error|warn"` |
| `!~` | Regex doesn't match | `!~ "debug|trace"` |
| `and` | Logical AND | `{a="1"} and {b="2"}` |
| `or` | Logical OR | `{a="1"} or {b="2"}` |

## Functions

| Function | Description | Example |
|----------|-------------|---------|
| `rate()` | Rate per second | `rate({container="api"}[5m])` |
| `count_over_time()` | Count logs | `count_over_time({level="error"}[5m])` |
| `sum()` | Sum values | `sum by (container) (...)` |
| `avg()` | Average | `avg(...)` |
| `min()` | Minimum | `min(...)` |
| `max()` | Maximum | `max(...)` |
| `topk()` | Top K | `topk(10, ...)` |
| `bottomk()` | Bottom K | `bottomk(5, ...)` |

## Examples by Use Case

### Debugging a service
```logql
# All logs
{container="jellyfin"}

# Only errors
{container="jellyfin", level="error"}

# Last 10 minutes
{container="jellyfin"}[10m]

# Search for specific error
{container="jellyfin"} |= "transcoding failed"
```

### API monitoring
```logql
# All API requests
{container="api"} | json

# Slow requests (>1s)
{container="api"} | json | duration > 1

# Failed requests
{container="api"} | json | status_code=~"5.."

# Requests per minute
rate({container="api"}[1m])
```

### Security monitoring
```logql
# Failed logins
{container="auth"} |= "login failed"

# Suspicious IPs
{container="proxy"} | json | ip !~ "192.168.*"

# Rate limit violations
{container="api"} |= "rate limit exceeded"
```

### Performance analysis
```logql
# Slowest endpoints
topk(10, avg by (endpoint) (duration))

# Error rate by service
sum by (container) (count_over_time({level="error"}[1h]))

# Log volume by service
sum by (container) (count_over_time({container!=""}[1h]))
```

## Tips

- **Start simple:** Begin with `{container="name"}`, then add filters
- **Use labels first:** `{level="error"}` is fast, `|= "error"` is slower
- **Limit results:** Add `| limit 100` to prevent overwhelming browser
- **Use time ranges:** Query smaller time windows for faster results
- **Check cardinality:** Avoid high-cardinality labels (user IDs, IPs)
- **Use line filters:** `|= "text"` is faster than regex `|~ "text"`

## Testing Queries

1. Open Grafana: https://monitor.mykyta-ryasny.dev
2. Go to Explore (compass icon)
3. Select Loki datasource
4. Enter query in query box
5. Click "Run query" or press Shift+Enter

## Advanced: Building Complex Queries

```logql
# Start with label selector
{container="api"}

# Add line filter
{container="api"} |= "POST"

# Parse logs
{container="api"} |= "POST" | json

# Filter parsed fields
{container="api"} |= "POST" | json | status_code="201"

# Format output
{container="api"} |= "POST" | json | status_code="201"
  | line_format "{{.timestamp}}: {{.method}} {{.endpoint}} - {{.status_code}}"

# Aggregate
sum by (endpoint) (
  count_over_time(
    {container="api"} |= "POST" | json | status_code="201" [5m]
  )
)
```

## Reference

- [Official LogQL Docs](https://grafana.com/docs/loki/latest/logql/)
- [LogQL Examples](https://grafana.com/docs/loki/latest/logql/log_queries/)
- [Metric Queries](https://grafana.com/docs/loki/latest/logql/metric_queries/)
