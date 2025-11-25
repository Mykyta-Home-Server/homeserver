---
description: "Quick overview of the home server automation project"
---

Provide a quick, friendly overview of the home server automation project.

Reference the architecture documentation:
@.claude/architecture.md

Include:
- What the project is (personal learning project to build home server with AI automation)
- Core concept (home server controllable via natural language through Telegram)
- Key components breakdown (infrastructure, services, automation layers)
- Technology stack summary
- Current phase and goals
- Security model highlights

Keep it concise and beginner-friendly - perfect for refreshing memory or explaining to someone new.

## Core Concept

Build a mini PC server that runs multiple services (media streaming, game servers, downloads) and control them using natural language through a Telegram bot powered by Claude AI.

**Example interaction:**
- You: "Download The Matrix"
- Bot: Downloads the movie, adds it to Plex, notifies you when ready
- You: "Create a new Minecraft survival server"
- Bot: Spins up a new server instance, configures it, gives you connection details

## Key Components

### Infrastructure Layer
- **Mini PC Server** - Physical hardware running Ubuntu Server
- **Docker** - Containers for service isolation
- **Caddy** - Reverse proxy for subdomain routing
- **Cloudflare Tunnel** - Secure external access (NO exposed ports)

### Services Layer
- **Plex** - Media streaming (movies, TV shows)
- **qBittorrent** - Download manager
- **Minecraft Servers** - Multiple game server instances

### Automation Layer
- **MCP Server** - Claude AI integration for command processing
- **Telegram Bot** - Natural language interface

## Technology Stack

| Component | Technology | Why? |
|-----------|-----------|------|
| OS | Ubuntu Server 22.04 LTS | Stable, well-supported |
| Containers | Docker + Compose | Easy management, isolation |
| Reverse Proxy | Caddy | Auto HTTPS, simple config |
| Security | Cloudflare Tunnel | No exposed ports, DDoS protection |
| AI | Claude API (Sonnet 4/4.5) | Natural language processing |
| Interface | Telegram Bot | Easy mobile access |

## Project Architecture (Simplified)

```
Internet → Cloudflare Tunnel → Caddy Reverse Proxy
                                    ↓
              ┌─────────────────────┼─────────────────────┐
              ↓                     ↓                     ↓
            Plex              qBittorrent           Minecraft

Natural Language Command (Telegram)
              ↓
         MCP Server + Claude AI
              ↓
    Executes Docker Operations
```

## Project Goals

### Primary Objectives
1. **Learn deeply** - Understand DNS, networking, containers, automation
2. **Build securely** - No exposed ports, proper isolation, secrets management
3. **Enable extensibility** - Easy to add new services
4. **Natural language control** - Control everything conversationally

### Learning Focus
This is NOT about quickly getting services running. It's about understanding:
- How DNS and reverse proxies work
- Container orchestration
- Network security
- AI automation integration
- Infrastructure as Code

## Current Phase

**Phase 1-2**: Foundation and Core Services
- Setting up infrastructure
- Deploying basic services
- Learning Docker and networking concepts

**Next Steps**: Building the MCP Server and Telegram bot for natural language automation

## Security Model

- ✅ **No exposed ports** on home network
- ✅ **Cloudflare Tunnel** for encrypted external access
- ✅ **Container isolation** - Services can't interfere with each other
- ✅ **Secrets management** - No hardcoded credentials
- ✅ **User authentication** - Telegram user whitelist

## Why This Matters

This project teaches you:
- Real-world DevOps practices
- Cloud-native architecture patterns
- Security best practices
- AI integration with infrastructure
- System automation

Plus, you get a powerful home server you fully understand and control!

## Quick Reference

**Documentation Files:**
- [architecture.md](.claude/architecture.md) - Full system architecture
- [technical_specs.md](.claude/technical_specs.md) - Detailed specifications
- [CLAUDE.md](CLAUDE.md) - Project instructions and philosophy

**For More Detail:** Use `/explain_deep` command

---

**TL;DR**: Building a secure home server with Plex, game servers, and downloads, controllable via natural language through Telegram + Claude AI. Learning DevOps, security, and AI automation along the way.
