#!/bin/bash
# ============================================================================
# Docker Log Rotation Setup Script
# ============================================================================
# Purpose: Configure Docker daemon for automatic log rotation
# Must be run with sudo
# ============================================================================

set -euo pipefail

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo ./setup-log-rotation.sh"
    exit 1
fi

echo "============================================"
echo "Docker Log Rotation Setup"
echo "============================================"
echo ""

# Backup existing daemon.json if it exists and has content
if [ -f /etc/docker/daemon.json ] && [ -s /etc/docker/daemon.json ]; then
    echo "Backing up existing /etc/docker/daemon.json..."
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ Backup created"
fi

# Create new daemon.json with log rotation settings
echo "Creating /etc/docker/daemon.json with log rotation settings..."
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
EOF

echo "✓ Configuration file created"
echo ""
echo "Log rotation settings:"
echo "  - Max log size: 10 MB per file"
echo "  - Max files: 3 (total 30 MB per container)"
echo "  - Compression: Enabled"
echo ""

# Restart Docker daemon
echo "Restarting Docker daemon to apply changes..."
echo "Warning: This will briefly interrupt all containers!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl restart docker
    echo "✓ Docker daemon restarted"
    echo ""
    echo "Waiting for Docker to be ready..."
    sleep 5

    # Verify Docker is running
    if systemctl is-active --quiet docker; then
        echo "✓ Docker is running"
    else
        echo "✗ Docker failed to start!"
        echo "Check logs with: sudo journalctl -u docker -n 50"
        exit 1
    fi

    echo ""
    echo "============================================"
    echo "Setup complete!"
    echo "============================================"
    echo ""
    echo "Next steps:"
    echo "1. Restart containers for changes to take effect:"
    echo "   cd /opt/homeserver && docker compose restart"
    echo ""
    echo "2. Verify log rotation is working:"
    echo "   docker inspect <container> | grep LogConfig -A 10"
else
    echo "Setup cancelled. Configuration file created but Docker not restarted."
    echo "Run 'sudo systemctl restart docker' when ready."
fi
