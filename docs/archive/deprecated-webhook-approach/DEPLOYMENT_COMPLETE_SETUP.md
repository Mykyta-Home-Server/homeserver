# 🎉 Deployment API - Complete Setup Guide

**Last Updated:** 2025-11-25
**Status:** ✅ **Production Ready with 7-Layer Security**

---

## 📋 Table of Contents

1. [What You Built](#what-you-built)
2. [Security Architecture](#security-architecture)
3. [Required Secrets](#required-secrets)
4. [Cloudflare WAF Setup](#cloudflare-waf-setup)
5. [GitHub Repository Setup](#github-repository-setup)
6. [Testing & Verification](#testing--verification)
7. [Troubleshooting](#troubleshooting)

---

## What You Built

A **custom FastAPI deployment microservice** that replaces the generic webhook library with a purpose-built, highly secure deployment solution.

### Features

- ✅ **7-layer security** (from edge to application)
- ✅ **HMAC-SHA256 authentication** (like GitHub webhooks)
- ✅ **Custom header validation** (Cloudflare + API)
- ✅ **Service whitelist** (only approved services)
- ✅ **Automatic health checks** (verify containers start)
- ✅ **Automatic rollback** (revert on failure)
- ✅ **Beautiful logging** (emoji-rich deployment logs)
- ✅ **RESTful API** (modern, clean design)

---

## Security Architecture

### 7 Security Layers

```
Internet Request
    ↓
1. Cloudflare Tunnel (no exposed ports)
    ↓
2. HTTPS/TLS (Caddy + Origin Certificates)
    ↓
3. Cloudflare WAF (custom header check at edge)
    ↓
4. X-Homeserver-Key header (application check)
    ↓
5. X-Deployment-Token header (static token)
    ↓
6. X-Hub-Signature-256 (HMAC cryptographic signature)
    ↓
7. Service Whitelist (allowed services only)
    ↓
✅ Deployment Proceeds
```

### Required Headers (All 3 Mandatory)

```http
X-Hub-Signature-256: sha256=<calculated_hmac>
X-Deployment-Token: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX
X-Homeserver-Key: REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Missing **any** header = **403 Forbidden**

---

## Required Secrets

### Server Secrets (`/opt/homeserver/.env`)

```bash
# HMAC signature secret
WEBHOOK_SECRET=REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Deployment token
DEPLOYMENT_TOKEN=REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX

# Homeserver key (for Cloudflare WAF)
HOMESERVER_KEY=REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**⚠️ NEVER commit .env to git!**

### GitHub Repository Secrets

For each repository that deploys via this API:

**Settings → Secrets and variables → Actions → New repository secret**

Add these **3 secrets**:

```
Name: WEBHOOK_SECRET
Value: REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Name: DEPLOYMENT_TOKEN
Value: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX

Name: HOMESERVER_KEY
Value: REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## Cloudflare WAF Setup

### Step 1: Create WAF Rule

**Cloudflare Dashboard → Security → WAF → Create rule**

**Rule name:** `Allow Deployment API with Custom Header`

**Expression:**

```
(http.request.uri.path eq "/deploy" and
 http.request.method eq "POST" and
 http.request.headers["x-homeserver-key"][0] eq "REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
```

**Action:** Skip → All remaining custom rules

### Step 2: Deploy Rule

Click **Deploy** to activate.

### Why This Is Needed

Cloudflare's WAF blocks automated traffic from GitHub Actions (datacenter IPs). This rule tells Cloudflare:

> "If the request has the correct custom header, allow it through"

Random attackers won't have this header, so they're still blocked.

**📖 Detailed Guide:** [CLOUDFLARE_WAF_SETUP.md](CLOUDFLARE_WAF_SETUP.md)

---

## GitHub Repository Setup

### Step 1: Add GitHub Workflow

Create `.github/workflows/deploy.yml` in your repository:

**Use the template:** [DEPLOYMENT_API_GITHUB_WORKFLOW.yml](DEPLOYMENT_API_GITHUB_WORKFLOW.yml)

Key sections:
```yaml
- name: Trigger deployment on home server
  env:
    WEBHOOK_SECRET: ${{ secrets.WEBHOOK_SECRET }}
    DEPLOYMENT_TOKEN: ${{ secrets.DEPLOYMENT_TOKEN }}
    HOMESERVER_KEY: ${{ secrets.HOMESERVER_KEY }}
  run: |
    # Calculate HMAC signature
    SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

    # Send deployment request with all authentication headers
    curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
      -H "Content-Type: application/json" \
      -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
      -H "X-Deployment-Token: $DEPLOYMENT_TOKEN" \
      -H "X-Homeserver-Key: $HOMESERVER_KEY" \
      -d "$PAYLOAD"
```

### Step 2: Add Secrets to Repository

See [Required Secrets](#required-secrets) above.

### Step 3: Test Deployment

```bash
git commit --allow-empty -m "Test deployment"
git push
```

Watch:
- GitHub Actions tab (build & deploy)
- Server logs: `docker logs deploy-api -f`

---

## Testing & Verification

### Local Security Test

```bash
bash /tmp/test_full_auth.sh
```

**Expected results:**
- Missing headers → `403 Forbidden`
- All headers present → Deployment proceeds

### External Endpoint Test

```bash
curl https://deploy.mykyta-ryasny.dev/health
```

**Expected:** `{"status":"healthy",...}`

### Full Deployment Test

```bash
PAYLOAD='{"service":"portal","image":"ghcr.io/mykytaryasny/homeserver-portal:latest"}'
SECRET="REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
TOKEN="REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX"
KEY="REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "X-Deployment-Token: $TOKEN" \
  -H "X-Homeserver-Key: $KEY" \
  -d "$PAYLOAD"
```

---

## Troubleshooting

### "Just a moment..." Cloudflare Page

**Cause:** Cloudflare WAF blocking (header missing or rule not configured)

**Fix:**
1. Verify WAF rule is deployed in Cloudflare
2. Check header is included: `X-Homeserver-Key`
3. Check header value matches exactly

### "403 Forbidden" from API

**Cause:** One of the authentication headers is wrong

**Fix:** Check logs to see which layer failed:
```bash
docker logs deploy-api --tail 20
```

Look for:
- `❌ Invalid homeserver key`
- `❌ Invalid deployment token`
- `❌ Invalid signature`

### GitHub Actions Fails with 403

**Cause:** GitHub secrets don't match server values or WAF rule not configured

**Fix:**
1. Verify all 3 secrets exist in GitHub repository
2. Verify values match `/opt/homeserver/.env` exactly
3. Verify Cloudflare WAF rule is active
4. Test manually with curl first

### Deployment Reaches API but Fails

**Cause:** Authentication passed, but deployment logic failed

**Fix:** Check deployment logs:
```bash
docker logs deploy-api -f
```

Common issues:
- Image doesn't exist or is private
- Service name not in whitelist
- Docker compose error

---

## 🎯 Quick Reference

### Server Files

```
/opt/homeserver/
├── .env                              # Secrets (NEVER commit!)
├── services/deployment/
│   ├── app.py                        # FastAPI application
│   ├── Dockerfile                    # Container definition
│   └── requirements.txt              # Python dependencies
├── compose/deployment.yml            # Docker compose service
└── docs/
    ├── CLOUDFLARE_WAF_SETUP.md      # Cloudflare configuration
    ├── DEPLOYMENT_API_GITHUB_WORKFLOW.yml  # Workflow template
    ├── DEPLOYMENT_API_SECURITY.md   # Security guide
    └── DEPLOYMENT_COMPLETE_SETUP.md # This file
```

### Commands

```bash
# View logs
docker logs deploy-api -f

# Restart API
docker compose restart deploy-api

# Rebuild API
docker compose build deploy-api && docker compose up -d deploy-api

# Test health
curl https://deploy.mykyta-ryasny.dev/health

# Check container
docker ps | grep deploy-api
```

### API Endpoints

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/` | GET | API info | No |
| `/health` | GET | Health check | No |
| `/deploy` | POST | Deploy service | Yes (3 headers) |

---

## 📚 Documentation Index

- **[CLOUDFLARE_WAF_SETUP.md](CLOUDFLARE_WAF_SETUP.md)** - Cloudflare WAF rule configuration
- **[DEPLOYMENT_API_GITHUB_WORKFLOW.yml](DEPLOYMENT_API_GITHUB_WORKFLOW.yml)** - GitHub Actions workflow template
- **[DEPLOYMENT_API_SECURITY.md](DEPLOYMENT_API_SECURITY.md)** - Complete security documentation
- **[DEPLOYMENT_SECURITY_SUMMARY.md](DEPLOYMENT_SECURITY_SUMMARY.md)** - Quick security summary
- **[DEPLOYMENT_COMPLETE_SETUP.md](DEPLOYMENT_COMPLETE_SETUP.md)** - This file

---

## ✅ Deployment Checklist

Before going live:

- [ ] Deploy-api container running
- [ ] Health endpoint accessible: `https://deploy.mykyta-ryasny.dev/health`
- [ ] All 3 secrets in `/opt/homeserver/.env`
- [ ] Cloudflare DNS record: `deploy.mykyta-ryasny.dev`
- [ ] Cloudflare WAF rule created and deployed
- [ ] WAF rule checks header: `x-homeserver-key`
- [ ] GitHub secrets added to repository (all 3)
- [ ] Workflow file created: `.github/workflows/deploy.yml`
- [ ] Tested manually with curl (success)
- [ ] Tested GitHub Actions deployment (success)

---

**Your deployment API is production-ready with enterprise-grade security!** 🎉🔒

**What makes this secure:**
- ✅ Defense in depth (7 layers)
- ✅ Cloudflare edge filtering (WAF)
- ✅ Multiple authentication methods
- ✅ Cryptographic signature verification
- ✅ No exposed ports (tunnel only)
- ✅ Service whitelist (command injection protection)
- ✅ Network isolation (internal only)

**Next Step:** Push code to GitHub and watch automated deployment! 🚀