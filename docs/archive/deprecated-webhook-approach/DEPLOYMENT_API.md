# Custom Deployment API Documentation

**Last Updated:** 2025-11-25

---

## Overview

Custom-built FastAPI microservice for automated Docker deployments. Replaces generic webhook tools with a purpose-built solution designed specifically for your home server.

**Features:**
- ✅ HMAC-SHA256 signature verification
- ✅ Service whitelist (prevents unauthorized deployments)
- ✅ Automatic health checks
- ✅ Automatic rollback on failure
- ✅ Detailed logging
- ✅ Docker Compose integration
- ✅ Clean API (no library quirks)

---

## Architecture

```
GitHub Actions
    ↓ (POST /deploy)
Cloudflare Tunnel → deploy.mykyta-ryasny.dev
    ↓
Deployment API (FastAPI on port 9000)
    ↓ (verifies HMAC signature)
Docker Socket
    ↓ (docker compose commands)
Service Container (portal, jellyfin, etc.)
```

---

## API Endpoints

### `GET /`
Root endpoint - API information

**Response:**
```json
{
  "service": "Home Server Deployment API",
  "version": "1.0.0",
  "status": "healthy",
  "endpoints": {
    "health": "/health",
    "deploy": "/deploy (POST)"
  }
}
```

### `GET /health`
Health check endpoint

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-25T09:54:25.496572",
  "compose_dir": "/homeserver"
}
```

### `POST /deploy`
Deploy a Docker service

**Headers:**
- `X-Hub-Signature-256`: HMAC-SHA256 signature of the request body
- `Content-Type`: application/json

**Body:**
```json
{
  "service": "portal",
  "image": "ghcr.io/mykytaryasny/homeserver-portal:latest",
  "repository": "MykytaRyasny/homeserver-portal",
  "commit": "abc123",
  "message": "Update homepage"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "service": "portal",
  "message": "Deployment successful",
  "old_image": "ghcr.io/mykytaryasny/homeserver-portal:main-xyz789",
  "new_image": "ghcr.io/mykytaryasny/homeserver-portal:latest",
  "steps": [
    {"step": "capture_state", "success": true, "image": "..."},
    {"step": "pull_image", "success": true},
    {"step": "compose_up", "success": true},
    {"step": "health_check", "success": true, "running": true}
  ]
}
```

**Response (Failure - 500):**
```json
{
  "success": false,
  "service": "portal",
  "error": "Container failed to start",
  "logs": "...",
  "steps": [...]
}
```

**Response (Invalid Signature - 403):**
```json
{
  "detail": "Invalid signature"
}
```

**Response (Invalid Service - 400):**
```json
{
  "detail": "Service 'xyz' not allowed. Allowed: portal, hello-world, ..."
}
```

---

## Allowed Services

Only whitelisted services can be deployed:

- `portal`
- `hello-world`
- `caddy`
- `authelia`
- `jellyfin`, `radarr`, `sonarr`, `prowlarr`, `jellyseerr`, `qbittorrent`
- `grafana`, `loki`, `promtail`, `uptime-kuma`

To add a service, edit `/opt/homeserver/services/deployment/app.py` line ~164.

---

## Deployment Flow

When you call `POST /deploy`:

1. **Signature Verification** - Verifies HMAC-SHA256 signature matches
2. **Service Validation** - Checks service is in whitelist
3. **Capture State** - Saves current container image for rollback
4. **Pull Image** - Downloads new image from registry (if specified)
5. **Restart Service** - Runs `docker compose up -d <service>`
6. **Health Check** - Waits 5s and verifies container is running
7. **Success** - Returns 200 and cleans up old image
8. **Failure** - Attempts rollback to previous image, returns 500

---

## Security

### HMAC Signature Calculation

The signature is calculated as:
```
HMAC-SHA256(secret, request_body)
```

**Example in Bash:**
```bash
PAYLOAD='{"service":"portal","image":"ghcr.io/.../portal:latest"}'
SECRET="your-secret-here"

SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')
echo "sha256=$SIGNATURE"
```

**Example in Python:**
```python
import hmac
import hashlib

payload = b'{"service":"portal",...}'
secret = "your-secret-here"

signature = hmac.new(
    secret.encode(),
    payload,
    hashlib.sha256
).hexdigest()

print(f"sha256={signature}")
```

### Secret Storage

The secret is stored in `/opt/homeserver/.env`:
```bash
WEBHOOK_SECRET=REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**GitHub Actions:**
- Add the same secret to: Settings → Secrets → Actions → `WEBHOOK_SECRET`

---

## Testing

### Test Health Endpoint
```bash
curl http://localhost:9000/health
```

### Test Deployment (With Valid Signature)
```bash
# Create payload
PAYLOAD='{"service":"portal","image":"ghcr.io/mykytaryasny/homeserver-portal:latest"}'

# Calculate signature
SECRET="REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

# Send request
curl -X POST http://localhost:9000/deploy \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

### Test External Access (After Cloudflare Propagation)
```bash
curl https://deploy.mykyta-ryasny.dev/health
```

---

## Logs

View deployment logs:
```bash
# Follow logs in real-time
docker logs deployment-api -f

# Show last 50 lines
docker logs deployment-api --tail 50

# Filter for errors
docker logs deployment-api | grep ERROR
```

**Log Format:**
```
2025-11-25 09:53:31,185 [INFO] ========================================
2025-11-25 09:53:31,185 [INFO] 🚀 Deployment Started: portal
2025-11-25 09:53:31,185 [INFO] ========================================
2025-11-25 09:53:31,185 [INFO] 📦 Service: portal
2025-11-25 09:53:31,185 [INFO] 🖼️  Image: ghcr.io/mykytaryasny/homeserver-portal:latest
2025-11-25 09:53:31,185 [INFO] 🕐 Time: 2025-11-25 09:53:31
2025-11-25 09:53:31,185 [INFO] ========================================
2025-11-25 09:53:32,123 [INFO] 📸 Capturing current state for rollback...
2025-11-25 09:53:33,456 [INFO] ⬇️  Pulling image: ghcr.io/...
2025-11-25 09:53:45,789 [INFO] 🔄 Restarting service via docker compose...
2025-11-25 09:53:50,123 [INFO] 🏥 Checking container health...
2025-11-25 09:53:51,456 [INFO] ========================================
2025-11-25 09:53:51,456 [INFO] ✅ Deployment Successful!
2025-11-25 09:53:51,456 [INFO] ========================================
```

---

## Troubleshooting

### "Invalid signature"
- Check that `WEBHOOK_SECRET` matches in `.env` and GitHub
- Verify payload format is exactly what's being signed
- Ensure no extra whitespace in payload

### "Service not allowed"
- Check service name spelling
- Add service to whitelist in `app.py` if needed

### Container fails to start after deployment
- Check logs: `docker logs <service>`
- Verify image exists and is pullable
- API automatically rolls back to previous image

### Deployment API not accessible externally
- Check Cloudflare Tunnel is running: `docker logs cloudflared`
- Verify DNS record points to tunnel CNAME
- Wait 10-15 minutes for Cloudflare propagation
- Check `deploy.mykyta-ryasny.dev` is proxied (orange cloud)

---

## Files

- **API Code:** `/opt/homeserver/services/deployment/app.py`
- **Dockerfile:** `/opt/homeserver/services/deployment/Dockerfile`
- **Requirements:** `/opt/homeserver/services/deployment/requirements.txt`
- **Compose Config:** `/opt/homeserver/compose/deployment.yml`
- **Tunnel Config:** `/opt/homeserver/services/tunnel/cloudflared/config.yml` (line 55-56)
- **Environment:** `/opt/homeserver/.env`
- **Workflow Example:** `/opt/homeserver/docs/github-actions-deployment-api.yml`

---

## Advantages Over Webhook Library

| Feature | Generic Webhook | Custom API |
|---------|----------------|------------|
| **Control** | Limited by library | Full control |
| **Debugging** | Opaque | Custom logging |
| **Features** | Fixed | Easy to extend |
| **Dependencies** | Library + Go/Node | Just Python |
| **Observability** | Basic | Detailed status |
| **Health Checks** | None | Built-in |
| **Rollback** | Manual | Automatic |

---

## Future Enhancements

Possible improvements:
- [ ] Telegram notifications on success/failure
- [ ] Deployment history/audit log
- [ ] Multiple environment support (staging/prod)
- [ ] Blue-green deployments
- [ ] Gradual rollout (canary deployments)
- [ ] Prometheus metrics export
- [ ] Rate limiting per service
- [ ] Scheduled deployments

---

**Related Docs:**
- [GitHub Actions Workflow](github-actions-deployment-api.yml)
- [Docker Guide](DOCKER_GUIDE.md)
- [Monitoring Guide](MONITORING_GUIDE.md)