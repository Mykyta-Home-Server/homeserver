# Documentation Index

Welcome to the Home Server documentation! This directory contains all user-facing guides and references.

## 📚 Quick Start

New to the project? Start here:
1. [Quick Reference](reference/QUICK_REFERENCE.md) - Essential commands cheat sheet
2. [Docker Guide](guides/DOCKER_GUIDE.md) - Complete Docker reference
3. [Adding Services](guides/ADDING_SERVICES.md) - How to add new services

## 📖 Guides

Step-by-step tutorials for common tasks:

| Guide | Description |
|-------|-------------|
| [Docker Guide](guides/DOCKER_GUIDE.md) | Complete Docker reference, commands, and troubleshooting |
| [Adding Services](guides/ADDING_SERVICES.md) | Step-by-step guide to adding new services |
| [Monitoring Guide](guides/MONITORING_GUIDE.md) | Monitoring stack setup, LogQL queries, dashboards |
| [Migration Guide](guides/MIGRATION_GUIDE.md) | VM to physical server migration |
| [LDAP Guide](guides/LDAP_GUIDE.md) | Complete LDAP user and group management |

## 📑 Reference

Quick references and cheat sheets:

| Reference | Description |
|-----------|-------------|
| [Quick Reference](reference/QUICK_REFERENCE.md) | Essential commands cheat sheet |
| [QoL Tools Guide](reference/QOL_TOOLS_GUIDE.md) | Productivity tools (bat, lazydocker, btop, etc.) |
| [Service Profiles](reference/SERVICE_PROFILES.md) | Docker Compose profiles reference |
| [Scripts Reference](reference/SCRIPTS.md) | All scripts documentation |
| [Maintenance Cron](reference/MAINTENANCE_CRON.md) | Dockerized cron jobs (Grafana integration) |

## ⚙️ Setup

Initial setup and configuration:

| Setup Guide | Description |
|-------------|-------------|
| [ZSH Setup](setup/ZSH_SETUP.md) | Shell configuration (Zsh + Starship) |
| [GitHub Runner Setup](setup/GITHUB_RUNNER_SETUP.md) | CI/CD self-hosted runner setup |

## 📁 Directory Structure

```
docs/
├── README.md                      # This file
│
├── guides/                        # How-to guides
│   ├── DOCKER_GUIDE.md
│   ├── MONITORING_GUIDE.md
│   ├── ADDING_SERVICES.md
│   ├── MIGRATION_GUIDE.md
│   └── LDAP_GUIDE.md
│
├── reference/                     # Quick references
│   ├── QUICK_REFERENCE.md
│   ├── QOL_TOOLS_GUIDE.md
│   ├── SERVICE_PROFILES.md
│   ├── SCRIPTS.md
│   └── MAINTENANCE_CRON.md
│
├── setup/                         # Initial setup
│   ├── ZSH_SETUP.md
│   └── GITHUB_RUNNER_SETUP.md
│
└── archive/                       # Archived/deprecated docs
    ├── auth-guides/              # Old LDAP guides (consolidated)
    └── deprecated-webhook-approach/
```

## 🤖 For Claude (AI Assistant)

Claude-specific documentation is in `/.claude/`:
- [Architecture](../.claude/architecture.md) - System design and data flows
- [Technical Specs](../.claude/technical_specs.md) - Hardware, software stack details
- [API Documentation](../.claude/api_documentation.md) - All API references

## 🔍 Finding Information

### I want to...

**...add a new service**
→ [Adding Services Guide](guides/ADDING_SERVICES.md)

**...understand Docker commands**
→ [Docker Guide](guides/DOCKER_GUIDE.md)

**...check service logs**
→ [Monitoring Guide](guides/MONITORING_GUIDE.md) + [Quick Reference](reference/QUICK_REFERENCE.md)

**...set up LDAP/SSO**
→ [LDAP Guide](guides/LDAP_GUIDE.md)

**...use quality of life tools**
→ [QoL Tools Guide](reference/QOL_TOOLS_GUIDE.md)

**...run a backup**
→ [Scripts Reference](reference/SCRIPTS.md)

**...migrate to new hardware**
→ [Migration Guide](guides/MIGRATION_GUIDE.md)

## 📝 Contributing to Documentation

When updating documentation:

1. **Follow naming conventions:**
   - Guides: `UPPER_SNAKE_CASE.md`
   - Keep related content in appropriate subdirectories

2. **Update this index** when adding new documents

3. **Include "Last Updated" date** at the bottom of each guide

4. **Test all commands** before documenting them

5. **Link to other docs** instead of duplicating content

## ⚡ Quick Commands

```bash
# View services status
docker compose ps

# Check logs
docker compose logs -f <service>

# Restart a service
docker compose restart <service>

# Start with profiles
docker compose --profile media --profile monitoring up -d

# Full backup
/opt/homeserver/scripts/backup.sh
```

For more commands, see [Quick Reference](reference/QUICK_REFERENCE.md).

---

**Last Updated:** 2025-11-27
