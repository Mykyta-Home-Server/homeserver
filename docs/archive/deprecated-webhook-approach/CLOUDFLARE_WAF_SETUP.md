# Cloudflare WAF Configuration for Deployment API

**Last Updated:** 2025-11-25

---

## 🎯 Purpose

Configure Cloudflare's Web Application Firewall (WAF) to allow GitHub Actions to reach your deployment API while maintaining security through custom header validation.

---

## 🔒 Security Strategy

**Problem:** Cloudflare blocks automated requests from GitHub Actions (looks like bot traffic)

**Solution:** Create a WAF rule that allows `/deploy` requests **only if they have the correct custom header**

This provides:
- ✅ Cloudflare WAF bypass for legitimate requests
- ✅ Additional authentication layer (custom header)
- ✅ Protection against random scanners (they won't have the header)
- ✅ DDoS protection still active

---

## 📋 Cloudflare WAF Rule Setup

### Step 1: Navigate to WAF

1. Log into **Cloudflare Dashboard**
2. Select your domain: `mykyta-ryasny.dev`
3. Go to: **Security → WAF**
4. Click: **Create rule**

### Step 2: Configure Rule

**Rule name:** `Allow Deployment API with Custom Header`

**When incoming requests match:**

```
(http.request.uri.path eq "/deploy" and
 http.request.method eq "POST" and
 http.request.headers["x-homeserver-key"][0] eq "REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
```

**Expression Editor (simple mode):**

Field | Operator | Value
------|----------|------
URI Path | equals | `/deploy`
AND | |
Method | equals | `POST`
AND | |
Header Name | equals | `x-homeserver-key`
AND | |
Header Value | equals | `REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

**Then:**
- Action: **Skip**
- Select: **All remaining custom rules**

### Step 3: Deploy

Click **Deploy** to save the rule.

---

## 🧪 Testing the Configuration

### Test 1: Request WITHOUT Custom Header (Should Fail)

```bash
curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "Content-Type: application/json" \
  -d '{"service":"portal","image":"test"}'
```

**Expected:** Cloudflare blocks with 403 (challenge page)

### Test 2: Request WITH Custom Header (Should Reach API)

```bash
curl -X POST https://deploy.mykyta-ryasny.dev/deploy \
  -H "Content-Type: application/json" \
  -H "X-Homeserver-Key: REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX" \
  -d '{"service":"portal","image":"test"}'
```

**Expected:** Reaches your API, gets 403 from API (missing other auth headers)

This confirms Cloudflare is checking the header!

### Test 3: Full Authenticated Request

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

**Expected:** Deployment starts successfully (200 OK)

---

## 🛡️ Security Layers Now Active (7 Total!)

| Layer | What It Does | Where It Checks |
|-------|-------------|-----------------|
| 1. Cloudflare Tunnel | No exposed ports | Network level |
| 2. HTTPS/TLS | Encrypted communication | Transport level |
| 3. **Cloudflare WAF Header** | Custom header validation | **Edge level (NEW!)** |
| 4. Homeserver Key | Custom header at API | Application level |
| 5. Deployment Token | Static token | Application level |
| 6. HMAC Signature | Cryptographic signature | Application level |
| 7. Service Whitelist | Allowed services only | Application level |

---

## 📊 How It Works

```
GitHub Actions
    ↓ (sends request with all 3 headers)
Cloudflare Edge Server
    ↓ (checks X-Homeserver-Key header)
    ↓ (if match → allow, if no match → block)
Cloudflare Tunnel
    ↓
Caddy (HTTPS)
    ↓
Deploy API
    ↓ (checks X-Homeserver-Key header again)
    ↓ (checks X-Deployment-Token header)
    ↓ (checks X-Hub-Signature-256 HMAC)
    ↓ (checks service whitelist)
    ↓
✅ Deployment proceeds
```

---

## 🔄 Alternative: IP-Based Rule

If you prefer to allow based on GitHub's IP ranges instead of custom header:

**Rule name:** `Allow GitHub Actions IPs`

**Expression:**
```
(http.request.uri.path eq "/deploy" and
 http.request.method eq "POST" and
 ip.src in {140.82.112.0/20 192.30.252.0/22 185.199.108.0/22 143.55.64.0/20})
```

**Then:** Skip → All remaining custom rules

**Note:** GitHub IPs can change. Verify current ranges at:
```bash
curl https://api.github.com/meta | jq .actions
```

---

## 🚨 Troubleshooting

### "Just a moment..." Cloudflare Challenge Page

**Cause:** WAF rule not configured or header missing

**Fix:**
1. Verify WAF rule is deployed in Cloudflare
2. Verify header name is exactly: `x-homeserver-key` (lowercase)
3. Verify header value matches exactly (64 hex characters)
4. Check rule priority (should be before other rules)

### Request Reaches API But Gets 403

**Cause:** Cloudflare passed, but API rejected

**Fix:** Check which header failed:
```bash
docker logs deploy-api --tail 20
```

Look for:
- `❌ Invalid homeserver key` → X-Homeserver-Key wrong
- `❌ Invalid deployment token` → X-Deployment-Token wrong
- `❌ Invalid signature` → HMAC signature wrong

### GitHub Actions Still Blocked

**Cause:** WAF rule not matching

**Fix:**
1. Test rule manually with curl first
2. Verify GitHub secret `HOMESERVER_KEY` is correct
3. Check Cloudflare Firewall Events log for blocked requests
4. Ensure rule action is "Skip" not "Block"

---

## 📝 GitHub Secrets Required

Add all three secrets to your repository:

**Settings → Secrets and variables → Actions → New repository secret**

```
Name: WEBHOOK_SECRET
Value: REDACTED_WEBHOOK_SECRET_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Name: DEPLOYMENT_TOKEN
Value: REDACTED_DEPLOYMENT_TOKEN_XXXXXXXXXXXXXXX

Name: HOMESERVER_KEY
Value: REDACTED_HOMESERVER_KEY_64_CHARS_XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## 🔐 Rotating the Homeserver Key

If you need to change the key:

### 1. Generate New Key

```bash
openssl rand -hex 32
```

### 2. Update Server

Edit `/opt/homeserver/.env`:
```bash
HOMESERVER_KEY=<new_key>
```

Restart deploy-api:
```bash
docker compose restart deploy-api
```

### 3. Update Cloudflare WAF Rule

Edit the rule and update the header value check.

### 4. Update GitHub Secrets

Update `HOMESERVER_KEY` in all repositories.

---

## ✅ Verification Checklist

Before testing GitHub Actions deployment:

- [ ] WAF rule created in Cloudflare
- [ ] Rule checks exact header name: `x-homeserver-key`
- [ ] Rule checks exact header value (64 chars)
- [ ] Rule action is "Skip" → "All remaining custom rules"
- [ ] Rule is deployed (not draft)
- [ ] `HOMESERVER_KEY` added to GitHub repository secrets
- [ ] Workflow updated to include header in curl command
- [ ] Tested manually with curl (success)

---

## 📚 Additional Resources

- **Cloudflare WAF Rules:** https://developers.cloudflare.com/waf/custom-rules/
- **GitHub Actions IP Ranges:** https://api.github.com/meta
- **Expression Reference:** https://developers.cloudflare.com/ruleset-engine/rules-language/

---

**Your deployment API is now protected at the Cloudflare edge with custom header validation!** 🚀