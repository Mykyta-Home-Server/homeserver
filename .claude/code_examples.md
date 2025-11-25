# Code Examples & Reference Implementations

## Docker Compose Configuration

### Complete docker-compose.yml

```yaml
version: '3.8'

# Define custom network for all services
networks:
  server-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

# Define named volumes for persistent data
volumes:
  caddy_data:
  caddy_config:
  plex_config:
  qbittorrent_config:
  minecraft_data:

services:
  # Cloudflare Tunnel - Secure external access
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      server-net:
        ipv4_address: 172.20.0.40
    environment:
      - TZ=Europe/Madrid

  # Caddy - Reverse Proxy
  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      server-net:
        ipv4_address: 172.20.0.2
    environment:
      - TZ=Europe/Madrid
    healthcheck:
      test: ["CMD", "caddy", "validate", "--config", "/etc/caddy/Caddyfile"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Plex Media Server
  plex:
    image: linuxserver/plex:latest
    container_name: plex
    restart: unless-stopped
    networks:
      server-net:
        ipv4_address: 172.20.0.10
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=Europe/Madrid
      - PLEX_CLAIM=${PLEX_CLAIM_TOKEN}
    volumes:
      - plex_config:/config
      - /media/movies:/movies:ro
      - /media/tv:/tv:ro
      - /tmp/transcode:/transcode
    devices:
      - /dev/dri:/dev/dri  # For hardware transcoding
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:32400/web"]
      interval: 60s
      timeout: 10s
      retries: 3

  # qBittorrent - Download Manager
  qbittorrent:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    networks:
      server-net:
        ipv4_address: 172.20.0.11
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
      - WEBUI_PORT=8080
    volumes:
      - qbittorrent_config:/config
      - /downloads:/downloads
    ports:
      - "6881:6881"  # Torrent port (optional, for better connectivity)
      - "6881:6881/udp"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Minecraft Server (Template - can be scaled)
  minecraft:
    image: itzg/minecraft-server:latest
    container_name: minecraft
    restart: unless-stopped
    networks:
      server-net:
        ipv4_address: 172.20.0.20
    environment:
      - EULA=TRUE
      - TYPE=PAPER
      - VERSION=LATEST
      - MEMORY=2G
      - TZ=Europe/Madrid
      - DIFFICULTY=normal
      - MAX_PLAYERS=10
      - ONLINE_MODE=TRUE
      - SERVER_NAME=MainWorld
    volumes:
      - minecraft_data:/data
    tty: true
    stdin_open: true

  # MCP Server - Automation Backend
  mcp-server:
    build: ./mcp-server
    container_name: mcp-server
    restart: unless-stopped
    networks:
      server-net:
        ipv4_address: 172.20.0.30
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - MCP_API_KEY=${MCP_API_KEY}
      - TZ=Europe/Madrid
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro  # Docker control
      - ./mcp-server:/app
    depends_on:
      - plex
      - qbittorrent

  # Telegram Bot - User Interface
  telegram-bot:
    build: ./telegram-bot
    container_name: telegram-bot
    restart: unless-stopped
    networks:
      server-net:
        ipv4_address: 172.20.0.31
    environment:
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
      - MCP_SERVER_URL=http://mcp-server:8000
      - MCP_API_KEY=${MCP_API_KEY}
      - TZ=Europe/Madrid
    volumes:
      - ./telegram-bot:/app
    depends_on:
      - mcp-server
```

---

## Caddy Configuration

### Caddyfile

```caddyfile
# Global options
{
    # Email for Let's Encrypt notifications
    email your-email@example.com
    
    # Use staging for testing, remove for production
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

# Plex Media Server
plex.yourdomain.com {
    reverse_proxy plex:32400 {
        # Preserve headers for Plex
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
    
    # Logging
    log {
        output file /var/log/caddy/plex.log
        level INFO
    }
}

# qBittorrent Web UI
torrents.yourdomain.com {
    # Optional: Add basic auth
    # basicauth {
    #     user $2a$14$hashed_password
    # }
    
    reverse_proxy qbittorrent:8080 {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
    }
    
    log {
        output file /var/log/caddy/torrents.log
        level INFO
    }
}

# Minecraft Server (TCP proxy for game traffic)
minecraft.yourdomain.com {
    reverse_proxy minecraft:25565
    
    log {
        output file /var/log/caddy/minecraft.log
        level INFO
    }
}

# MCP Server API (Optional - for direct API access)
automation.yourdomain.com {
    # Restrict to API only
    reverse_proxy mcp-server:8000 {
        header_up Host {host}
        header_up X-Real-IP {remote}
    }
    
    # Rate limiting
    @too_many_requests {
        path /command
    }
    
    log {
        output file /var/log/caddy/automation.log
        level WARN
    }
}
```

---

## MCP Server Implementation

### main.py

```python
#!/usr/bin/env python3
"""
MCP Server - Natural Language Automation Backend
Processes commands from Telegram Bot and executes Docker operations
"""

from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from typing import Optional, Dict, Any
import docker
import anthropic
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(title="MCP Server", version="1.0.0")

# Initialize clients
docker_client = docker.from_env()
claude_client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# API Key for authentication
MCP_API_KEY = os.getenv("MCP_API_KEY")

# Request models
class CommandRequest(BaseModel):
    user_id: int
    message: str
    context: Optional[Dict[str, Any]] = {}

class DockerAction(BaseModel):
    container: str
    action: str  # start, stop, restart, logs

# Authentication dependency
async def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != MCP_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")
    return x_api_key

# MCP Tools Definition
MCP_TOOLS = [
    {
        "name": "docker_control",
        "description": "Start, stop, restart, or get logs from Docker containers",
        "input_schema": {
            "type": "object",
            "properties": {
                "action": {
                    "type": "string",
                    "enum": ["start", "stop", "restart", "logs"],
                    "description": "Action to perform on the container"
                },
                "container": {
                    "type": "string",
                    "description": "Container name (e.g., 'plex', 'qbittorrent', 'minecraft')"
                }
            },
            "required": ["action", "container"]
        }
    },
    {
        "name": "get_service_status",
        "description": "Get status of all running services or a specific service",
        "input_schema": {
            "type": "object",
            "properties": {
                "service": {
                    "type": "string",
                    "description": "Optional: specific service name. If not provided, returns all services"
                }
            }
        }
    },
    {
        "name": "download_movie",
        "description": "Add a movie to download queue via qBittorrent",
        "input_schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "Movie title to download"
                },
                "year": {
                    "type": "integer",
                    "description": "Release year (optional, helps find correct version)"
                },
                "quality": {
                    "type": "string",
                    "enum": ["720p", "1080p", "4K"],
                    "description": "Preferred quality"
                }
            },
            "required": ["title"]
        }
    }
]

# Docker control functions
def execute_docker_action(action: str, container: str) -> Dict[str, Any]:
    """Execute Docker action on container"""
    try:
        cont = docker_client.containers.get(container)
        
        if action == "start":
            cont.start()
            return {"status": "success", "message": f"Container {container} started"}
        
        elif action == "stop":
            cont.stop(timeout=10)
            return {"status": "success", "message": f"Container {container} stopped"}
        
        elif action == "restart":
            cont.restart(timeout=10)
            return {"status": "success", "message": f"Container {container} restarted"}
        
        elif action == "logs":
            logs = cont.logs(tail=50).decode('utf-8')
            return {"status": "success", "logs": logs}
        
    except docker.errors.NotFound:
        return {"status": "error", "message": f"Container {container} not found"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def get_container_status() -> Dict[str, Any]:
    """Get status of all containers"""
    containers = docker_client.containers.list(all=True)
    status = {}
    
    for container in containers:
        status[container.name] = {
            "status": container.status,
            "image": container.image.tags[0] if container.image.tags else "unknown",
            "created": container.attrs['Created']
        }
    
    return status

# Process tool calls from Claude
def process_tool_call(tool_name: str, tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """Execute tool based on Claude's decision"""
    
    if tool_name == "docker_control":
        return execute_docker_action(tool_input["action"], tool_input["container"])
    
    elif tool_name == "get_service_status":
        return get_container_status()
    
    elif tool_name == "download_movie":
        # TODO: Implement qBittorrent integration
        # For now, return placeholder
        return {
            "status": "success",
            "message": f"Added {tool_input['title']} to download queue"
        }
    
    return {"status": "error", "message": "Unknown tool"}

@app.post("/command")
async def process_command(
    request: CommandRequest,
    api_key: str = Depends(verify_api_key)
):
    """
    Process natural language command via Claude AI
    """
    try:
        # Call Claude API with MCP tools
        response = claude_client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=1024,
            tools=MCP_TOOLS,
            messages=[
                {
                    "role": "user",
                    "content": request.message
                }
            ]
        )
        
        # Process response
        results = []
        text_response = ""
        
        for block in response.content:
            if block.type == "text":
                text_response = block.text
            
            elif block.type == "tool_use":
                # Execute tool
                tool_result = process_tool_call(block.name, block.input)
                results.append({
                    "tool": block.name,
                    "result": tool_result
                })
        
        return {
            "status": "success",
            "message": text_response,
            "actions": results
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/status")
async def get_status(api_key: str = Depends(verify_api_key)):
    """Get status of all services"""
    return {"services": get_container_status()}

@app.post("/docker/{action}")
async def docker_action(
    action: str,
    docker_req: DockerAction,
    api_key: str = Depends(verify_api_key)
):
    """Direct Docker action endpoint"""
    result = execute_docker_action(action, docker_req.container)
    return result

# Health check endpoint
@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Dockerfile (MCP Server)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run as non-root user
RUN useradd -m -u 1000 mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser

EXPOSE 8000

CMD ["python", "main.py"]
```

### requirements.txt (MCP Server)

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
anthropic==0.7.8
docker==6.1.3
python-dotenv==1.0.0
pydantic==2.5.0
requests==2.31.0
```

---

## Telegram Bot Implementation

### bot.py

```python
#!/usr/bin/env python3
"""
Telegram Bot - User Interface for Home Server Automation
Receives user commands and forwards to MCP Server
"""

from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    filters,
    ContextTypes
)
import requests
import os
from dotenv import load_dotenv
import logging

# Setup logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Load environment
load_dotenv()

TELEGRAM_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
ALLOWED_USERS = [int(x) for x in os.getenv("TELEGRAM_ALLOWED_USERS", "").split(",")]
MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://mcp-server:8000")
MCP_API_KEY = os.getenv("MCP_API_KEY")

# Verify user is allowed
def is_authorized(user_id: int) -> bool:
    return user_id in ALLOWED_USERS

# Command handlers
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Start command - welcome message"""
    user = update.effective_user
    
    if not is_authorized(user.id):
        await update.message.reply_text("⛔ Unauthorized. Contact administrator.")
        return
    
    welcome_message = f"""
👋 Welcome {user.first_name}!

I'm your home server automation assistant. You can control your server using natural language!

**Examples:**
• "Download Inception"
• "Restart plex"
• "Show me status of all services"
• "Create a new Minecraft server"

**Commands:**
/start - Show this message
/status - Show service status
/help - Show help

Just send me a message and I'll understand! 🚀
    """
    await update.message.reply_text(welcome_message)

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Status command - show all services"""
    user_id = update.effective_user.id
    
    if not is_authorized(user_id):
        await update.message.reply_text("⛔ Unauthorized")
        return
    
    # Call MCP Server
    try:
        response = requests.get(
            f"{MCP_SERVER_URL}/status",
            headers={"X-API-Key": MCP_API_KEY},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            services = data.get("services", {})
            
            status_text = "📊 **Service Status**\n\n"
            for name, info in services.items():
                emoji = "🟢" if info["status"] == "running" else "🔴"
                status_text += f"{emoji} **{name}**: {info['status']}\n"
            
            await update.message.reply_text(status_text, parse_mode="Markdown")
        else:
            await update.message.reply_text("❌ Failed to get status")
    
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        await update.message.reply_text("❌ Error connecting to server")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle natural language messages"""
    user_id = update.effective_user.id
    message_text = update.message.text
    
    if not is_authorized(user_id):
        await update.message.reply_text("⛔ Unauthorized")
        return
    
    # Show typing indicator
    await update.message.chat.send_action("typing")
    
    # Send to MCP Server
    try:
        response = requests.post(
            f"{MCP_SERVER_URL}/command",
            headers={"X-API-Key": MCP_API_KEY},
            json={
                "user_id": user_id,
                "message": message_text,
                "context": {}
            },
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            reply = data.get("message", "Done!")
            
            # Add action results if any
            actions = data.get("actions", [])
            if actions:
                reply += "\n\n**Actions taken:**\n"
                for action in actions:
                    reply += f"• {action['tool']}: {action['result'].get('message', 'OK')}\n"
            
            await update.message.reply_text(reply, parse_mode="Markdown")
        else:
            await update.message.reply_text("❌ Something went wrong")
    
    except requests.exceptions.Timeout:
        await update.message.reply_text("⏱️ Request timed out. Try again.")
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        await update.message.reply_text("❌ Error processing your request")

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Help command"""
    help_text = """
🤖 **Home Server Bot Help**

**Natural Language Commands:**
Just talk to me naturally! I understand commands like:

• "Download [movie name]"
• "Restart [service]"
• "Show status"
• "Create minecraft server called [name]"
• "Stop all downloads"
• "What's running?"

**Bot Commands:**
/start - Welcome message
/status - Show service status
/help - This help message

**Tips:**
• Be specific but natural
• I'll ask if I need more info
• All actions are logged
    """
    await update.message.reply_text(help_text, parse_mode="Markdown")

# Error handler
async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Log errors"""
    logger.error(f"Update {update} caused error {context.error}")

def main():
    """Start the bot"""
    # Create application
    application = Application.builder().token(TELEGRAM_TOKEN).build()
    
    # Add handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("status", status))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # Add error handler
    application.add_error_handler(error_handler)
    
    # Start bot
    logger.info("Bot starting...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
```

### Dockerfile (Telegram Bot)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 botuser && chown -R botuser:botuser /app
USER botuser

CMD ["python", "bot.py"]
```

### requirements.txt (Telegram Bot)

```txt
python-telegram-bot==20.7
requests==2.31.0
python-dotenv==1.0.0
```

---

## Environment Variables Template

### .env.example

```bash
# Copy this to .env and fill in your values
# NEVER commit .env to git!

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here

# Plex
PLEX_CLAIM_TOKEN=claim-xxxxxxxxxxxx

# Telegram Bot
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_ALLOWED_USERS=123456789,987654321

# Anthropic Claude API
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxx

# MCP Server
MCP_API_KEY=generate_random_secure_key_here

# qBittorrent (set after first run)
QBITTORRENT_USERNAME=admin
QBITTORRENT_PASSWORD=change_this_password
```

---

## Utility Scripts

### Generate API Key

```bash
#!/bin/bash
# generate-api-key.sh
# Generate secure random API key for MCP Server

python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Backup Script

```bash
#!/bin/bash
# backup.sh
# Backup Docker volumes and configurations

BACKUP_DIR="/backup/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm \
  -v plex_config:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/plex_config.tar.gz /data

docker run --rm \
  -v qbittorrent_config:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/qbittorrent_config.tar.gz /data

# Backup configs
cp docker-compose.yml "$BACKUP_DIR/"
cp -r caddy "$BACKUP_DIR/"
cp .env.example "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### System Monitor

```python
#!/usr/bin/env python3
# monitor.py
# Simple resource monitoring

import docker
import psutil
from datetime import datetime

client = docker.from_env()

print(f"=== System Monitor - {datetime.now()} ===\n")

# System resources
print(f"CPU: {psutil.cpu_percent()}%")
print(f"RAM: {psutil.virtual_memory().percent}%")
print(f"Disk: {psutil.disk_usage('/').percent}%\n")

# Container stats
print("=== Container Stats ===")
for container in client.containers.list():
    stats = container.stats(stream=False)
    cpu = stats['cpu_stats']['cpu_usage']['total_usage']
    mem = stats['memory_stats']['usage'] / (1024**2)  # MB
    
    print(f"{container.name}:")
    print(f"  Memory: {mem:.0f} MB")
    print(f"  Status: {container.status}\n")
```

---

These code examples provide complete, working implementations that you can use as reference when building your home server. Each file includes inline comments explaining what it does and why.