#!/bin/bash
# Docker Compose Aliases for Home Server
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source /opt/homeserver/docker-compose-aliases.sh

# ============================================================================
# Docker Compose with --profile all (includes media & monitoring)
# ============================================================================

alias dcup='docker compose --profile all up -d'
alias dcdown='docker compose --profile all down'
alias dcrestart='docker compose --profile all restart'
alias dcps='docker compose --profile all ps'
alias dclogs='docker compose --profile all logs -f'
alias dcpull='docker compose --profile all pull'

# Specific service management
alias dcstop='docker compose --profile all stop'
alias dcstart='docker compose --profile all start'
alias dcbuild='docker compose --profile all build'

# Useful shortcuts
alias dclogs-tail='docker compose --profile all logs --tail=50 -f'
alias dcexec='docker compose exec'
alias dcstats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"'

# Profile-specific commands
alias dcup-core='docker compose up -d'  # Only core services (no profiles)
alias dcup-media='docker compose --profile media up -d'
alias dcup-monitoring='docker compose --profile monitoring up -d'

echo "✅ Docker Compose aliases loaded!"
echo "   Use 'dcup' to start all services"
echo "   Use 'dcdown' to stop all services"
echo "   Use 'dcps' to list all services"
