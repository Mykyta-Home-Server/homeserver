---
title: Quick Reference
description: Fast lookup for common commands and essential information
---

Essential commands and information for daily operations.

## System Info

```bash
VM Name:    Ubuntu-HomeServer-PoC
Hostname:   home-server
Username:   mykyta
Current IP: 192.168.1.200
SSH:        ssh mykyta@home-server
Project:    /opt/homeserver
```

## Docker Commands

### Container Management

```bash
docker ps                    # Running containers
docker ps -a                 # All containers
docker logs <container>      # View logs
docker logs -f <container>   # Follow logs
docker exec -it <container> bash  # Enter container
```

### Docker Compose

```bash
cd /opt/homeserver
docker compose up -d         # Start services
docker compose down          # Stop services
docker compose ps            # Status
docker compose logs -f       # Follow logs
docker compose restart <service>  # Restart one service
docker compose pull          # Pull latest images
```

### Cleanup

```bash
docker system prune -a       # Remove unused data
docker image prune           # Remove unused images
docker volume prune          # Remove unused volumes
```

## System Commands

```bash
# Update system
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

# System info
lsb_release -a    # OS version
nproc             # CPU cores
free -h           # RAM
df -h             # Disk space
```

## Network Commands

```bash
hostname -I                  # Check IP
ip addr show eth0 | grep inet
ping -c 4 google.com         # Test connectivity
ip route | grep default      # Check gateway
```

## Git Commands

```bash
git status
git log --oneline -10
git add .
git commit -m "Your message"
git push
```

## Common File Locations

| Path | Purpose |
|------|---------|
| `/opt/homeserver/` | Main project directory |
| `/opt/homeserver/docker-compose.yml` | Service definitions |
| `/opt/homeserver/.env` | Environment variables |
| `/opt/homeserver/services/` | Service configurations |
| `/opt/homeserver/data/media/` | Media files |

## Port Reference

| Service | Port | Description |
|---------|------|-------------|
| Caddy | 80, 443 | Reverse proxy |
| Jellyfin | 8096 | Media server |
| qBittorrent | 8080 | Torrent client |
| Radarr | 7878 | Movie management |
| Sonarr | 8989 | TV management |
| Prowlarr | 9696 | Indexer management |
| Grafana | 3000 | Monitoring |

## Troubleshooting

### Docker Issues

```bash
sudo systemctl status docker  # Check if running
sudo systemctl restart docker # Restart Docker
groups $USER                  # Check docker group
sudo usermod -aG docker $USER # Add to docker group
```

### Network Issues

```bash
nslookup google.com          # DNS test
sudo systemctl restart systemd-networkd  # Restart networking
```

### Disk Full

```bash
df -h                         # Check disk usage
docker system df              # Docker disk usage
docker system prune -a        # Clean Docker
sudo apt clean                # Clean apt cache
```
