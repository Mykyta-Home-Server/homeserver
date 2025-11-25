# User Documentation

This folder contains all user-facing documentation for setting up and maintaining the home server.

## 📚 Documentation Files

### Core Guides (Comprehensive)

- **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)** - Complete Docker reference
  - Part 1: Installation & Setup
  - Part 2: Quick Commands Reference
  - Part 3: Recovery Procedures
  - Part 4: Troubleshooting

- **[MONITORING_GUIDE.md](MONITORING_GUIDE.md)** - Monitoring stack complete guide
  - Architecture deep dive (Loki, Promtail, Grafana)
  - Configuration explanations
  - Deployment steps
  - LogQL Quick Reference (Appendix)

### System Setup Guides

- **[ZSH_SETUP_SOLUTION.md](ZSH_SETUP_SOLUTION.md)** - ZSH shell configuration guide
  - Oh My Zsh installation
  - Plugin setup
  - VS Code integration
  - Troubleshooting

- **[QOL_TOOLS_GUIDE.md](QOL_TOOLS_GUIDE.md)** - Quality of Life tools reference
  - Tool descriptions and use cases
  - Command examples
  - Configuration tips
  - Quick reference tables

### Service & Infrastructure Guides

- **[adding-services.md](adding-services.md)** - Complete guide for adding new Docker services
  - Step-by-step tutorial
  - Docker Compose configuration
  - Caddy reverse proxy setup
  - Cloudflare Tunnel configuration
  - Examples and troubleshooting

- **[GITHUB_RUNNER_SETUP.md](GITHUB_RUNNER_SETUP.md)** - GitHub Actions self-hosted runner guide
  - Runner setup and configuration
  - Docker-in-Docker implementation
  - CI/CD pipeline integration
  - Troubleshooting and maintenance

- **[SERVICE_PROFILES.md](SERVICE_PROFILES.md)** - Service management with Docker Compose profiles
  - Profile definitions and usage
  - Selective service deployment
  - Environment-specific configurations

- **[migration-guide.md](migration-guide.md)** - VM to physical server migration guide
  - Pre-migration checklist
  - Backup procedures
  - Physical server setup
  - Restoration steps
  - Post-migration verification

### Quick References

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Essential commands and information
  - Common operations
  - Quick troubleshooting
  - Network information
  - System details

### Setup Scripts

- **[setup-quality-of-life.sh](setup-quality-of-life.sh)** - Automated QoL tools installation
  - Installs ZSH, Oh My Zsh, and productivity tools
  - Run with: `bash setup-quality-of-life.sh`

## 🎯 Purpose

These documents are designed to help you:
- Set up the home server from scratch
- Understand each component and why it's used
- Troubleshoot common issues independently
- Reference commands quickly during work

## 📖 How to Use This Documentation

1. **First Time Setup**: Read guides in this order:
   - [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Install Docker
   - [ZSH_SETUP_SOLUTION.md](ZSH_SETUP_SOLUTION.md) - Setup shell
   - [QOL_TOOLS_GUIDE.md](QOL_TOOLS_GUIDE.md) - Install productivity tools

2. **Adding New Services**: Follow this guide:
   - [adding-services.md](adding-services.md) (complete step-by-step tutorial)

3. **Setting Up Monitoring**: Follow this guide:
   - [MONITORING_GUIDE.md](MONITORING_GUIDE.md) (Loki + Grafana stack)

4. **Daily Work**: Keep these open for quick reference:
   - [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick commands
   - [DOCKER_GUIDE.md](DOCKER_GUIDE.md) Part 2 - Docker commands

5. **Migrating to Physical Server**: When ready:
   - [migration-guide.md](migration-guide.md) (complete migration process)

6. **Troubleshooting**: Each guide has a dedicated troubleshooting section

## 📋 Documentation Standards

All documentation in this folder follows established standards:
- **Naming**: ALL_CAPS for guides, lowercase-with-hyphens for technical docs
- **Structure**: Overview → Main Content → Troubleshooting → References
- **Updates**: Each file includes "Last Updated" date
- **Cross-references**: Relative links to related documentation

For complete standards, see [CLAUDE.md](../CLAUDE.md) "Documentation Standards" section.

## 🔗 Related Documentation

- **Session Notes**: See [../sessions/](../sessions/) for project progress and session summaries
- **Claude Instructions**: See [../CLAUDE.md](../CLAUDE.md) for AI assistant configuration
- **Architecture Docs**: See [../.claude/](../.claude/) for system architecture and technical specs
- **Service-Specific Docs**: See individual service folders (e.g., `../services/proxy/caddy/README.md`)
- **Archived Documentation**: See [archive/](archive/) for deprecated approaches and historical documentation

## 📦 Archive

The [archive/](archive/) directory contains deprecated documentation for reference:
- **deprecated-webhook-approach/** - Old webhook-based deployment system (replaced by GitHub Actions runner)

---

**Last Updated**: 2025-11-25
