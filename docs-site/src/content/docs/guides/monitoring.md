---
title: Monitoring Guide
description: Grafana Loki centralized logging setup
---

Centralized logging with Grafana, Loki, and Promtail.

## Stack Overview

| Component | Purpose |
|-----------|---------|
| **Loki** | Log aggregation and storage |
| **Promtail** | Collects logs from Docker containers |
| **Grafana** | Visualization and querying |

## Access

- **Grafana**: `https://monitor.mykyta-ryasny.dev`

## LogQL Queries

### Basic Queries

```logql
# View all logs from a container
{container="jellyfin"}

# Filter by service group
{service_group="media"}

# Find errors
{container!=""} |= "error"
```

### Advanced Queries

```logql
# Count errors per minute
count_over_time({level="error"}[1m])

# Top 5 noisiest containers
topk(5, sum by (container) (count_over_time({container!=""}[1h])))

# Parse JSON logs
{container="caddy"} | json | status >= 400
```

## Labels

Promtail automatically adds labels from Docker:

| Label | Description |
|-------|-------------|
| `container` | Container name |
| `compose_service` | Docker Compose service name |
| `compose_project` | Docker Compose project |
| `service_group` | Custom label (media, auth, etc.) |

## Configuration

### Loki (`loki-config.yml`)

```yaml
schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 720h  # 30 days
```

### Promtail (`promtail-config.yml`)

```yaml
scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: container
```

## Troubleshooting

### No logs appearing

```bash
# Check Promtail
docker logs promtail --tail 20

# Check Loki health
curl http://localhost:3100/ready
```

### Query returns nothing

- Ensure label exists: `{container="name"}`
- Check time range in Grafana
- Verify container is running
