# Deployment API Security Guide

**Last Updated:** 2025-11-25

---

## 🔐 Security Overview

Your deployment API is protected by **6 layers of security**:

### 1. **Cloudflare Tunnel**
- No ports exposed to the internet
- Traffic routed through Cloudflare's secure tunnel
- Protection against DDoS attacks

### 2. **HTTPS/TLS Encryption**
- All traffic encrypted via Caddy with Cloudflare Origin Certificates
- Prevents man-in-the-middle attacks

### 3. **HMAC-SHA256 Signature Verification**
- Every request must include `X-Hub-Signature-256` header
- Cryptographic signature proves request authenticity
- Uses shared secret between GitHub and your server

### 4. **Deployment Token Header**
- Every request must include `X-Deployment-Token` header
- Additional static token for defense in depth
- Rejects requests missing this header immediately

### 5. **Service Whitelist**
- Only approved services can be deployed
- Prevents unauthorized deployments
- Protection against command injection

### 6. **Internal Network Isolation**
- Deploy API runs on internal network only
- Only accessible through Caddy reverse proxy
- No direct external access

---

## 🔑 Required Headers

Every deployment request **must** include both headers:

```bash
X-Hub-Signature-256: sha256=<hmac_signature>
X-Deployment-Token: <deployment_token>
```

**Without these headers, requests are rejected with 403 Forbidden.**

---

## 🧪 Testing Security

### Test 1: Missing Deployment Token (Should Fail)

```bash
PAYLOAD='{"service":"portal","image":"ghcr.io/user/portal:latest"}'
SECRET="REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

**Expected:** `{"detail":"Forbidden"}` (403)

---

### Test 2: Invalid HMAC Signature (Should Fail)

```bash
curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "X-Hub-Signature-256: sha256=invalid" \
  -H "X-Deployment-Token: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX" \
  -H "Content-Type: application/json" \
  -d '{"service":"portal","image":"ghcr.io/user/portal:latest"}'
```

**Expected:** `{"detail":"Invalid signature"}` (403)

---

### Test 3: Valid Request (Should Succeed)

```bash
PAYLOAD='{"service":"portal","image":"ghcr.io/mykytaryasny/homeserver-portal:latest"}'
SECRET="REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
TOKEN="REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX"
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "X-Deployment-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

**Expected:** Deployment starts (200 OK)

---

## 📝 Environment Variables

These secrets are stored in `/opt/homeserver/.env`:

```bash
# HMAC signature secret (64 characters)
WEBHOOK_SECRET=REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Deployment token (custom string)
DEPLOYMENT_TOKEN=REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
```

**⚠️ NEVER commit .env to git!**

---

## 🔧 GitHub Repository Setup

For each repository you want to deploy from GitHub Actions:

### Step 1: Add Secrets

Go to: **Repository → Settings → Secrets and variables → Actions**

Add two secrets:

**1. WEBHOOK_SECRET**
```
REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**2. DEPLOYMENT_TOKEN**
```
REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
```

### Step 2: Create Workflow

Copy `/opt/homeserver/docs/DEPLOYMENT_API_GITHUB_WORKFLOW.yml` to:
```
.github/workflows/deploy.yml
```

The workflow automatically:
- Builds Docker image
- Pushes to GHCR
- Calculates HMAC signature
- Sends deployment request with both headers
- Verifies deployment success

---

## 🛡️ Attack Scenarios & Protection

| Attack | Protection |
|--------|-----------|
| **Random internet scanner** | Cloudflare Tunnel blocks all direct access |
| **Replay attack** | HMAC signature changes with each unique payload |
| **Stolen deployment token** | Still needs HMAC signature with secret |
| **Stolen HMAC secret** | Still needs deployment token header |
| **Malicious service deployment** | Service whitelist rejects unknown services |
| **Command injection** | Service name validated against whitelist |
| **DDoS attack** | Cloudflare rate limiting + tunnel protection |
| **Man-in-the-middle** | HTTPS/TLS encryption end-to-end |

---

## 🔄 Rotating Secrets

If you need to rotate secrets:

### 1. Generate New Secrets

```bash
# New HMAC secret (64 hex characters)
openssl rand -hex 32

# New deployment token (custom string)
echo "homeserver-deploy-$(date +%Y)-$(openssl rand -hex 8)"
```

### 2. Update Server

Edit `/opt/homeserver/.env`:
```bash
WEBHOOK_SECRET=<new_secret>
DEPLOYMENT_TOKEN=<new_token>
```

Restart deploy-api:
```bash
docker compose restart deploy-api
```

### 3. Update GitHub

Update both secrets in **all** repositories using the deployment API.

---

## 📊 Monitoring Security

### Check Recent Access Attempts

```bash
docker logs deploy-api --tail 100 | grep "❌"
```

Shows all failed authentication attempts with IP addresses.

### Watch Live Deployments

```bash
docker logs deploy-api -f
```

Real-time stream of all deployment activity.

### Caddy Access Logs

```bash
docker exec caddy tail -f /var/log/caddy/webhook.log
```

All HTTP requests to deploy.mykyta-ryasny.dev endpoint.

---

## ✅ Security Checklist

Before going live, verify:

- [ ] `WEBHOOK_SECRET` is a strong random value (64 chars)
- [ ] `DEPLOYMENT_TOKEN` is a unique value
- [ ] `.env` file is NOT committed to git
- [ ] Both secrets added to GitHub repository secrets
- [ ] Service whitelist contains only your services
- [ ] Deploy-api is on `internal` network only
- [ ] Caddy is proxying correctly
- [ ] Cloudflare Tunnel is connected
- [ ] HTTPS is working (test with curl)
- [ ] Health endpoint is public (no auth)
- [ ] Deploy endpoint requires both headers

---

## 🚨 Troubleshooting

### "403 Forbidden" Response

**Cause:** Missing or invalid `X-Deployment-Token` header

**Fix:** Ensure header is included:
```bash
-H "X-Deployment-Token: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX"
```

### "403 Invalid signature" Response

**Cause:** HMAC signature mismatch

**Fix:**
1. Verify `WEBHOOK_SECRET` matches in both .env and GitHub secret
2. Ensure payload is **exactly** the same when calculating signature
3. Use `echo -n` (no newline) when calculating

### Deployment Works Locally But Not From GitHub

**Cause:** GitHub secrets don't match server .env values

**Fix:**
1. Check values in `/opt/homeserver/.env`
2. Update GitHub secrets to match exactly
3. Restart workflow

---

## 📚 References

- **FastAPI Security**: https://fastapi.tiangolo.com/tutorial/security/
- **HMAC Authentication**: https://en.wikipedia.org/wiki/HMAC
- **GitHub Actions Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **Cloudflare Tunnel**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

---

**Your deployment API is now secured with industry-standard authentication!** 🎉
