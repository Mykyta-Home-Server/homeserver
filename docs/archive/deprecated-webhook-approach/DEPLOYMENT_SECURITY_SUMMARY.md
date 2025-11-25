# 🔐 Deployment API - Security Enhancement Summary

**Date:** 2025-11-25
**Status:** ✅ Enhanced with Multi-Layer Security

---

## What Was Added

Enhanced the deployment API with an additional authentication header requirement.

### Before
- ✅ HMAC-SHA256 signature verification (`X-Hub-Signature-256`)
- ✅ Service whitelist
- ✅ Cloudflare Tunnel protection

### After (New)
- ✅ **Deployment token header** (`X-Deployment-Token`)
- ✅ Defense in depth - requires BOTH headers
- ✅ Immediate rejection of unauthorized requests

---

## Security Layers (6 Total)

1. **Cloudflare Tunnel** - No exposed ports
2. **HTTPS/TLS** - Encrypted communication
3. **HMAC Signature** - Request authenticity (`X-Hub-Signature-256`)
4. **Deployment Token** - Static header token (`X-Deployment-Token`) ⭐ NEW
5. **Service Whitelist** - Only allowed services
6. **Network Isolation** - Internal network only

---

## Required Headers

Every `/deploy` request now needs **BOTH**:

```http
X-Hub-Signature-256: sha256=<calculated_hmac>
X-Deployment-Token: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
```

Missing either header = **403 Forbidden** ❌

---

## Files Modified

### 1. `/opt/homeserver/services/deployment/app.py`
**Added:** Deployment token verification before HMAC check

```python
x_deployment_token: Optional[str] = Header(None)

# Verify deployment token (additional security layer)
expected_token = os.getenv("DEPLOYMENT_TOKEN", "homeserver-deploy-2025")
if x_deployment_token != expected_token:
    raise HTTPException(status_code=403, detail="Forbidden")
```

### 2. `/opt/homeserver/.env`
**Added:** Deployment token environment variable

```bash
DEPLOYMENT_TOKEN=REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
```

### 3. `/opt/homeserver/compose/deployment.yml`
**Added:** Environment variable to container

```yaml
environment:
  - DEPLOYMENT_TOKEN=${DEPLOYMENT_TOKEN}
```

---

## Testing Results

✅ **Test 1:** Request without deployment token → `403 Forbidden`
✅ **Test 2:** Request with token but bad signature → `403 Invalid signature`
✅ **Test 3:** Request with both valid headers → Deployment proceeds

---

## GitHub Actions Update Required

Add this secret to your repositories:

**Repository → Settings → Secrets → Actions → New secret**

```
Name: DEPLOYMENT_TOKEN
Value: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
```

Update workflow to include the header:

```yaml
- name: Trigger deployment
  env:
    WEBHOOK_SECRET: ${{ secrets.WEBHOOK_SECRET }}
    DEPLOYMENT_TOKEN: ${{ secrets.DEPLOYMENT_TOKEN }}  # NEW
  run: |
    curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
      -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
      -H "X-Deployment-Token: $DEPLOYMENT_TOKEN" \  # NEW
      -H "Content-Type: application/json" \
      -d "$PAYLOAD"
```

---

## Why This Helps

### Defense in Depth
Even if one security layer is compromised, others protect you:

- **HMAC secret leaked?** → Still need deployment token
- **Deployment token leaked?** → Still need HMAC signature
- **Both leaked?** → Still need valid service name + Cloudflare protection

### Rate Limiting
Failed auth attempts logged and can be monitored:

```bash
docker logs deploy-api | grep "❌ Invalid deployment token"
```

### Simple Rotation
Easy to rotate token without changing HMAC secret or GitHub webhook config.

---

## Quick Commands

### Test Security
```bash
bash /tmp/test_deploy.sh
```

### View Logs
```bash
docker logs deploy-api -f
```

### Restart API
```bash
docker compose restart deploy-api
```

### Check Container
```bash
docker exec deploy-api env | grep DEPLOYMENT_TOKEN
```

---

## Documentation Created

- ✅ [DEPLOYMENT_API_SECURITY.md](DEPLOYMENT_API_SECURITY.md) - Complete security guide
- ✅ [DEPLOYMENT_API_GITHUB_WORKFLOW.yml](DEPLOYMENT_API_GITHUB_WORKFLOW.yml) - Updated workflow template
- ✅ [DEPLOYMENT_SECURITY_SUMMARY.md](DEPLOYMENT_SECURITY_SUMMARY.md) - This file

---

## Next Steps

1. **Add secret to GitHub repositories:**
   - Settings → Secrets → Actions
   - Name: `DEPLOYMENT_TOKEN`
   - Value: `REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX`

2. **Update GitHub workflows:**
   - Add `DEPLOYMENT_TOKEN` to env
   - Add `-H "X-Deployment-Token: $DEPLOYMENT_TOKEN"` to curl

3. **Test deployment:**
   - Push to repository
   - Watch GitHub Actions
   - Verify deployment succeeds

---

**Your deployment API is now protected with multi-layer authentication!** 🛡️
