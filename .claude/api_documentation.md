# API Documentation

## Overview

This document describes all APIs used in the home server automation project, including external services and internal components.

---

## External APIs

### 1. Cloudflare API

**Base URL**: `https://api.cloudflare.com/client/v4`
**Authentication**: Bearer token
**Documentation**: https://developers.cloudflare.com/api/

#### Used Endpoints

##### Get Tunnel Information
```http
GET /accounts/{account_id}/cfd_tunnel/{tunnel_id}
Authorization: Bearer {api_token}
```

**Response:**
```json
{
  "success": true,
  "result": {
    "id": "tunnel-id",
    "name": "home-server-tunnel",
    "status": "healthy"
  }
}
```

##### Create DNS Record
```http
POST /zones/{zone_id}/dns_records
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "type": "CNAME",
  "name": "plex",
  "content": "tunnel-id.cfargotunnel.com",
  "proxied": true
}
```

**Use Case**: Automated subdomain creation when adding new services

---

### 2. Anthropic Claude API

**Base URL**: `https://api.anthropic.com/v1`
**Authentication**: X-API-Key header
**Documentation**: https://docs.anthropic.com/

#### Messages Endpoint

```http
POST /messages
x-api-key: {api_key}
anthropic-version: 2023-06-01
Content-Type: application/json

{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 1024,
  "tools": [...],
  "messages": [
    {
      "role": "user",
      "content": "Download Inception movie"
    }
  ]
}
```

**Response:**
```json
{
  "id": "msg_abc123",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "I'll help you download that movie."
    },
    {
      "type": "tool_use",
      "id": "toolu_xyz",
      "name": "download_movie",
      "input": {
        "title": "Inception",
        "year": 2010
      }
    }
  ]
}
```

**MCP Tools Definition:**
```python
tools = [
    {
        "name": "docker_control",
        "description": "Start, stop, or restart Docker containers",
        "input_schema": {
            "type": "object",
            "properties": {
                "action": {
                    "type": "string",
                    "enum": ["start", "stop", "restart"],
                    "description": "Action to perform"
                },
                "container": {
                    "type": "string",
                    "description": "Container name"
                }
            },
            "required": ["action", "container"]
        }
    }
]
```

---

### 3. Telegram Bot API

**Base URL**: `https://api.telegram.org/bot{token}`
**Authentication**: Token in URL
**Documentation**: https://core.telegram.org/bots/api

#### Send Message
```http
POST /bot{token}/sendMessage
Content-Type: application/json

{
  "chat_id": 123456789,
  "text": "Download completed!",
  "parse_mode": "Markdown"
}
```

#### Set Webhook
```http
POST /bot{token}/setWebhook
Content-Type: application/json

{
  "url": "https://automation.yourdomain.com/telegram/webhook",
  "allowed_updates": ["message", "callback_query"]
}
```

**Webhook Payload (Incoming):**
```json
{
  "update_id": 123456,
  "message": {
    "message_id": 789,
    "from": {
      "id": 123456789,
      "first_name": "User"
    },
    "chat": {
      "id": 123456789,
      "type": "private"
    },
    "date": 1635789012,
    "text": "Download Inception"
  }
}
```

---

## Docker APIs

### 4. Docker Engine API

**Base URL**: `unix:///var/run/docker.sock`
**Version**: 1.43
**Documentation**: https://docs.docker.com/engine/api/

#### List Containers
```http
GET /containers/json?all=true
```

**Response:**
```json
[
  {
    "Id": "abc123",
    "Names": ["/plex"],
    "Image": "linuxserver/plex:latest",
    "State": "running",
    "Status": "Up 2 days"
  }
]
```

#### Start Container
```http
POST /containers/{id}/start
```

**Response**: `204 No Content` on success

#### Stop Container
```http
POST /containers/{id}/stop?t=10
```

**Parameters:**
- `t`: Timeout in seconds before killing

#### Container Logs
```http
GET /containers/{id}/logs?stdout=true&stderr=true&tail=100
```

**Response**: Stream of log lines

#### Container Stats
```http
GET /containers/{id}/stats?stream=false
```

**Response:**
```json
{
  "cpu_stats": {
    "cpu_usage": {
      "total_usage": 123456789
    }
  },
  "memory_stats": {
    "usage": 536870912,
    "limit": 2147483648
  }
}
```

**Python Usage Example:**
```python
import docker

client = docker.from_env()

# Start container
container = client.containers.get('plex')
container.start()

# Get logs
logs = container.logs(tail=100).decode('utf-8')

# Get stats
stats = container.stats(stream=False)
```

---

### 5. Docker Compose API

**CLI-based** (no HTTP API)
**Documentation**: https://docs.docker.com/compose/

**Python Usage (via subprocess):**
```python
import subprocess

# Start services
subprocess.run(['docker-compose', 'up', '-d'])

# Restart service
subprocess.run(['docker-compose', 'restart', 'plex'])

# Scale service
subprocess.run(['docker-compose', 'up', '-d', '--scale', 'minecraft=3'])
```

---

## Service-Specific APIs

### 6. qBittorrent Web API

**Base URL**: `http://qbittorrent:8080`
**Authentication**: Cookie-based
**Documentation**: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API

#### Login
```http
POST /api/v2/auth/login
Content-Type: application/x-www-form-urlencoded

username=admin&password=adminpass
```

**Response**: Sets `SID` cookie

#### Add Torrent
```http
POST /api/v2/torrents/add
Cookie: SID={session_id}
Content-Type: multipart/form-data

urls=magnet:?xt=urn:btih:...
savepath=/downloads/movies
category=movies
```

#### Get Torrents List
```http
GET /api/v2/torrents/info?category=movies
Cookie: SID={session_id}
```

**Response:**
```json
[
  {
    "hash": "abc123",
    "name": "Inception.2010.1080p",
    "size": 2147483648,
    "progress": 0.75,
    "dlspeed": 5242880,
    "state": "downloading"
  }
]
```

#### Delete Torrent
```http
POST /api/v2/torrents/delete
Cookie: SID={session_id}
Content-Type: application/x-www-form-urlencoded

hashes=abc123&deleteFiles=false
```

**Python Wrapper Example:**
```python
class QBittorrentAPI:
    def __init__(self, url, username, password):
        self.url = url
        self.session = requests.Session()
        self.login(username, password)
    
    def login(self, username, password):
        response = self.session.post(
            f"{self.url}/api/v2/auth/login",
            data={"username": username, "password": password}
        )
        return response.text == "Ok."
    
    def add_torrent(self, magnet_url, save_path):
        return self.session.post(
            f"{self.url}/api/v2/torrents/add",
            data={"urls": magnet_url, "savepath": save_path}
        )
    
    def get_torrents(self):
        response = self.session.get(f"{self.url}/api/v2/torrents/info")
        return response.json()
```

---

### 7. Plex Media Server API

**Base URL**: `http://plex:32400`
**Authentication**: X-Plex-Token header
**Documentation**: https://www.plexopedia.com/plex-media-server/api/

#### Get Libraries
```http
GET /library/sections
X-Plex-Token: {token}
```

**Response:**
```xml
<MediaContainer>
  <Directory key="1" title="Movies" type="movie"/>
  <Directory key="2" title="TV Shows" type="show"/>
</MediaContainer>
```

#### Refresh Library
```http
GET /library/sections/{section_id}/refresh
X-Plex-Token: {token}
```

**Response**: `200 OK`

#### Get Active Sessions
```http
GET /status/sessions
X-Plex-Token: {token}
```

**Response:**
```xml
<MediaContainer>
  <Video title="Inception" user="Username" transcodeSession="..."/>
</MediaContainer>
```

**Python Helper:**
```python
class PlexAPI:
    def __init__(self, url, token):
        self.url = url
        self.token = token
        self.headers = {"X-Plex-Token": token}
    
    def refresh_library(self, section_id=1):
        response = requests.get(
            f"{self.url}/library/sections/{section_id}/refresh",
            headers=self.headers
        )
        return response.status_code == 200
    
    def get_sessions(self):
        response = requests.get(
            f"{self.url}/status/sessions",
            headers=self.headers
        )
        return response.text  # Parse XML as needed
```

---

## Internal APIs

### 8. MCP Server API

**Base URL**: `http://mcp-server:8000`
**Authentication**: API Key header
**Custom Implementation**

#### Process Command
```http
POST /command
X-API-Key: {api_key}
Content-Type: application/json

{
  "user_id": 123456789,
  "message": "Download Inception",
  "context": {}
}
```

**Response:**
```json
{
  "status": "success",
  "action": "download_movie",
  "details": {
    "title": "Inception",
    "torrent_added": true,
    "eta": "2 hours"
  },
  "message": "Started downloading Inception. I'll notify you when it's done!"
}
```

#### Get Service Status
```http
GET /status
X-API-Key: {api_key}
```

**Response:**
```json
{
  "services": {
    "plex": {
      "status": "running",
      "uptime": "2d 5h 30m",
      "active_streams": 1
    },
    "qbittorrent": {
      "status": "running",
      "active_downloads": 2,
      "download_speed": "5.2 MB/s"
    },
    "minecraft": {
      "status": "running",
      "players_online": 3,
      "server_tps": 20.0
    }
  }
}
```

#### Docker Control
```http
POST /docker/{action}
X-API-Key: {api_key}
Content-Type: application/json

{
  "container": "plex",
  "action": "restart"
}
```

**Actions**: `start`, `stop`, `restart`, `logs`

**Response:**
```json
{
  "status": "success",
  "container": "plex",
  "action": "restart",
  "message": "Container restarted successfully"
}
```

#### Create Minecraft Server
```http
POST /minecraft/create
X-API-Key: {api_key}
Content-Type: application/json

{
  "name": "SurvivalWorld",
  "memory": "4G",
  "version": "1.20.4",
  "type": "PAPER"
}
```

**Response:**
```json
{
  "status": "success",
  "server": {
    "name": "SurvivalWorld",
    "url": "survivalworld.yourdomain.com:25565",
    "container_id": "abc123"
  }
}
```

---

## Webhooks

### 9. qBittorrent Download Complete Webhook

**Configured In**: qBittorrent settings
**Trigger**: Torrent download completion
**Method**: POST

**Request:**
```http
POST https://automation.yourdomain.com/webhook/download-complete
Content-Type: application/json

{
  "hash": "abc123",
  "name": "Inception.2010.1080p",
  "category": "movies",
  "save_path": "/downloads/movies",
  "size": 2147483648,
  "completion_time": 1635789012
}
```

**Handler Action:**
1. Receive webhook
2. Trigger Plex library scan
3. Send Telegram notification
4. Log event

---

## Rate Limits & Quotas

### Anthropic Claude API
- **Tier 1**: 50 requests/minute
- **Tier 2**: 1,000 requests/minute
- **Tier 3**: 2,000 requests/minute
- **Daily token limit**: Varies by tier

### Telegram Bot API
- **Sending messages**: 30 messages/second
- **Per chat**: 1 message/second
- **Group messages**: 20 messages/minute

### Cloudflare API
- **Free tier**: 1,200 requests/5 minutes
- **Pro tier**: Higher limits

### Docker API
- **Local**: No enforced limits (system resources only)

---

## Error Handling

### Standard Error Response Format

```json
{
  "status": "error",
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Container 'plex' is not running",
    "details": {
      "container": "plex",
      "state": "exited"
    }
  }
}
```

### Common Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `UNAUTHORIZED` | Invalid API key | Check authentication |
| `NOT_FOUND` | Resource not found | Verify container/service name |
| `SERVICE_UNAVAILABLE` | Service is down | Check service status |
| `RATE_LIMIT_EXCEEDED` | Too many requests | Implement backoff |
| `INVALID_INPUT` | Bad request data | Validate input |
| `TIMEOUT` | Operation timed out | Retry with exponential backoff |

---

## Authentication Examples

### Storing Secrets Securely

```python
# .env file (never commit!)
ANTHROPIC_API_KEY=sk-ant-xxx
TELEGRAM_BOT_TOKEN=123456:ABC-DEF
QBITTORRENT_PASSWORD=secure_password
PLEX_TOKEN=xxx
MCP_API_KEY=generated_key

# Loading in Python
from dotenv import load_dotenv
import os

load_dotenv()

ANTHROPIC_KEY = os.getenv('ANTHROPIC_API_KEY')
```

### API Key Generation

```python
import secrets

# Generate secure API key for MCP Server
api_key = secrets.token_urlsafe(32)
print(f"Generated API Key: {api_key}")
```

---

## Testing APIs

### Using cURL

```bash
# Test MCP Server
curl -X POST http://localhost:8000/command \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 123, "message": "status"}'

# Test qBittorrent
curl -X POST http://localhost:8080/api/v2/auth/login \
  -d "username=admin&password=adminpass"

# Test Docker API
curl --unix-socket /var/run/docker.sock \
  http://localhost/containers/json
```

### Using Python

```python
import requests

# Test MCP Server
response = requests.post(
    "http://localhost:8000/command",
    headers={"X-API-Key": "your-key"},
    json={"user_id": 123, "message": "status"}
)
print(response.json())
```

---

## API Integration Flow Example

### Complete Download Movie Workflow

```
1. User sends Telegram message: "Download Inception"
   
2. Telegram Bot receives webhook
   POST /telegram/webhook
   → Validates user ID
   → Extracts message text

3. Bot calls MCP Server
   POST /command
   {
     "user_id": 123456789,
     "message": "Download Inception"
   }

4. MCP Server calls Claude API
   POST https://api.anthropic.com/v1/messages
   → Claude interprets: "download movie"
   → Returns tool_use with parameters

5. MCP Server calls qBittorrent API
   POST /api/v2/torrents/add
   → Searches for torrent
   → Adds to download queue

6. MCP Server responds to Telegram Bot
   {
     "status": "success",
     "message": "Started downloading..."
   }

7. Bot sends confirmation to user
   POST https://api.telegram.org/bot{token}/sendMessage

8. qBittorrent completes download
   → Triggers webhook
   POST /webhook/download-complete

9. MCP Server receives webhook
   → Calls Plex API to refresh library
   → Sends Telegram notification

10. User receives completion message
    → Can now stream via Plex
```

---

## Future API Integrations

### Planned Additions

1. **Home Assistant API** - Smart home integration
2. **Sonarr/Radarr APIs** - Automated media management
3. **Prometheus/Grafana** - Monitoring and metrics
4. **Authentik/Authelia** - Unified authentication
5. **Backup service APIs** - Automated backups

---

## References

- **Anthropic Claude**: https://docs.anthropic.com/
- **Docker Engine**: https://docs.docker.com/engine/api/
- **Telegram Bot**: https://core.telegram.org/bots/api
- **qBittorrent**: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API
- **Plex**: https://www.plexopedia.com/plex-media-server/api/
- **Cloudflare**: https://developers.cloudflare.com/api/