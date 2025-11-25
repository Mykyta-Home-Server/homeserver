# Quick Deployment API Test Guide

**Quick commands to test your deployment API**

---

## ✅ Quick Health Check

```bash
# Local
curl http://localhost:9000/health | jq

# External (after Cloudflare propagation)
curl https://deploy.mykyta-ryasny.dev/health | jq
```

**Expected:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-25T09:59:48.856145",
  "compose_dir": "/homeserver"
}
```

---

## 🚀 Test Deployment

```bash
# Set variables
PAYLOAD='{"service":"portal","image":"ghcr.io/mykytaryasny/homeserver-portal:latest"}'
SECRET="REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Calculate signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

# Send deployment request
curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | jq
```

---

## 📊 Watch Logs

```bash
# Follow deployment logs in real-time
docker logs deploy-api -f

# Show last 50 lines
docker logs deploy-api --tail 50
```

---

## 🔍 Check Container Status

```bash
# Check if running
docker ps | grep deploy-api

# Check health
docker inspect deploy-api --format='{{.State.Health.Status}}'

# Check networks
docker inspect deploy-api --format='{{range .NetworkSettings.Networks}}{{.NetworkID}} {{end}}'
```

---

## 🌐 Test External Access

After Cloudflare DNS propagates (10-15 min), test from GitHub Actions or another machine:

```bash
curl -v https://deploy.mykyta-ryasny.dev/health
```

**Good:** `HTTP/2 200`
**Bad:** `HTTP/2 530` (Error 1033 - still propagating, wait longer)

---

## 🎯 Full End-to-End Test

1. **Push to GitHub:**
   ```bash
   git commit --allow-empty -m "Test deployment"
   git push
   ```

2. **Watch GitHub Actions:**
   - Go to repository → Actions tab
   - Watch workflow execution

3. **Watch Server Logs:**
   ```bash
   docker logs deploy-api -f
   ```

4. **Verify Container Updated:**
   ```bash
   docker ps | grep portal
   docker images | grep portal
   ```

---

**File:** `/opt/homeserver/docs/WEBHOOK_QUICK_TEST.md`
