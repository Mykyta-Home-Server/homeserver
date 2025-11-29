---
title: Introduction
description: Welcome to the Home Server documentation
---

Welcome to the **Home Server** documentation! This project is a personal learning journey to build a comprehensive home server with AI-powered natural language automation.

## Current Infrastructure

The server currently runs **24 containers** providing:

| Category | Services |
|----------|----------|
| **Infrastructure** | Caddy (reverse proxy), Cloudflare Tunnel |
| **Authentication** | Authelia (SSO), PostgreSQL, Redis, OpenLDAP |
| **Media** | Jellyfin, Sonarr, Radarr, Prowlarr, Jellyseerr, qBittorrent, Bazarr |
| **Monitoring** | Grafana, Loki, Promtail |
| **Maintenance** | Dockerized cron jobs |
| **CI/CD** | Self-hosted GitHub Runner |

## Architecture Overview

```
Internet → Cloudflare (DNS + DDoS) → Encrypted Tunnel → Caddy (Reverse Proxy) → Docker Containers
```

### Key Features

- **Zero exposed ports** - All traffic through Cloudflare Tunnel
- **Single Sign-On** - Authelia with LDAP backend
- **Centralized logging** - Grafana Loki stack
- **Media automation** - Complete *arr stack with automatic subtitles
- **Infrastructure as Code** - Everything version-controlled

## Quick Links

- [Quick Reference](/homeserver/reference/quick-reference) - Essential commands
- [Docker Guide](/homeserver/guides/docker) - Container management
- [Adding Services](/homeserver/guides/adding-services) - Deploy new services
- [Monitoring](/homeserver/guides/monitoring) - Logs and observability

## Technology Stack

| Component | Technology |
|-----------|------------|
| OS | Ubuntu Server 22.04 LTS |
| Containers | Docker + Compose |
| Reverse Proxy | Caddy |
| Tunnel | Cloudflare Tunnel |
| CI/CD | GitHub Actions |
