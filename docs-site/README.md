# Home Server Documentation

> Comprehensive infrastructure documentation for a personal learning and development project

## 🎯 Project Overview

This is a personal home server project focused on learning fundamental DevOps concepts including Docker, networking, reverse proxies, CI/CD, and automation. The goal is to build a secure, extensible infrastructure that serves as both a learning platform and a production-ready home server.

## ✨ What's Working

- **Core Infrastructure** - Docker, Caddy, Cloudflare Tunnel
- **Media Stack** - Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent, Jellyseerr
- **Authentication** - Authelia with PostgreSQL and Redis
- **Monitoring** - Grafana + Loki + Promtail
- **Uptime Monitoring** - Uptime Kuma
- **CI/CD** - GitHub Actions self-hosted runner
- **Custom Web Apps** - Angular portal with automated deployment

## 🚀 Quick Start

New to the project? Start here:

1. **[Docker Setup](DOCKER_GUIDE.md)** - Install Docker and learn essential commands
2. **[Adding Services](adding-services.md)** - Learn how to add new services to the stack
3. **[GitHub Runner](GITHUB_RUNNER_SETUP.md)** - Understand the CI/CD pipeline
4. **[Quick Reference](QUICK_REFERENCE.md)** - Essential commands at a glance

## 📚 Core Guides

### Infrastructure & Setup

- **[Docker Guide](DOCKER_GUIDE.md)** - Complete Docker reference
- **[Monitoring Setup](MONITORING_GUIDE.md)** - Grafana, Loki, and Promtail
- **[Adding Services](adding-services.md)** - Step-by-step service deployment guide
- **[Migration Guide](migration-guide.md)** - VM to physical server migration

### Development & Deployment

- **[GitHub Actions Runner](GITHUB_RUNNER_SETUP.md)** - Self-hosted CI/CD setup
- **[Service Profiles](SERVICE_PROFILES.md)** - Managing services with profiles

### Productivity & Tools

- **[ZSH Setup](ZSH_SETUP_SOLUTION.md)** - Shell configuration guide
- **[Quality of Life Tools](QOL_TOOLS_GUIDE.md)** - Productivity tools reference
- **[Quick Reference](QUICK_REFERENCE.md)** - Commands and shortcuts

## 🏗️ Architecture

### Current Deployment Flow

```
Code Push → GitHub → Self-Hosted Runner → Build Image → Push to GHCR → Pull & Deploy
```

### Directory Structure

```
/opt/homeserver/
├── compose/              # Docker Compose service definitions
├── services/             # Service-specific configurations
├── docs/                 # Documentation (you are here)
├── scripts/              # Utility scripts
└── docker-compose.yml    # Main compose file
```

## 🛠️ Technology Stack

- **OS:** Ubuntu Server 22.04 LTS
- **Containerization:** Docker + Docker Compose
- **Reverse Proxy:** Caddy
- **Security:** Cloudflare Tunnel
- **CI/CD:** GitHub Actions (self-hosted)
- **Monitoring:** Grafana, Loki, Promtail

## 📖 Learning Resources

This project emphasizes **understanding WHY** things work, not just copying commands. Each guide includes:

- Explanations of underlying concepts
- Links to official documentation
- Troubleshooting sections
- Best practices

## 🔐 Security

- ✅ No exposed ports (Cloudflare Tunnel)
- ✅ Automatic HTTPS (Caddy)
- ✅ Authentication layer (Authelia)
- ✅ Secrets management (gitignored)
- ✅ Container isolation

## 📝 Contributing

This is a personal learning project, but the documentation structure and patterns can be useful for others building similar infrastructure.

## 📦 Archive

Historical documentation (deprecated approaches) can be found in the [archive section](archive/deprecated-webhook-approach/README.md).

---

**Last Updated:** 2025-11-25
