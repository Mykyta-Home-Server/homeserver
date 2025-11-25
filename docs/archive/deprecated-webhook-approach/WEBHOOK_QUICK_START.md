# Webhook Deployment - Quick Start

**5-Minute Setup Guide**

---

## What You Have Now ✅

All files are configured and ready to go:

1. ✅ **Webhook container** running on internal network
2. ✅ **Deploy script** at `/opt/homeserver/scripts/deploy/deploy-portal.sh`
3. ✅ **Webhook config** at `/opt/homeserver/scripts/webhooks/hooks.json`
4. ✅ **Caddy routing** for `deploy.mykyta-ryasny.dev`
5. ✅ **Cloudflare Tunnel** routing configured
6. ✅ **GitHub Actions workflow** template ready

---

## What You Need to Do

### 1. Generate Webhook Secret (1 min)

```bash
openssl rand -hex 32
```

**Copy the output** - you'll need it twice.

### 2. Update Webhook Config (1 min)

```bash
nano /opt/homeserver/scripts/webhooks/hooks.json
```

Replace line 26:
```json
"secret": "YOUR_WEBHOOK_SECRET_HERE"
```

With:
```json
"secret": "paste_your_generated_secret_here"
```

Save: `Ctrl+X`, `Y`, `Enter`

### 3. Restart Webhook (30 sec)

```bash
cd /opt/homeserver
docker compose restart webhook
docker logs webhook --tail 5
```

Should see: `Starting server on :9000`

### 4. Add Secret to GitHub (1 min)

1. Go to your portal repository on GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**
4. Name: `WEBHOOK_SECRET`
5. Value: (paste the same secret from step 1)
6. **Add secret**

### 5. Add Workflow to Your Repo (1 min)

In your portal repository:

```bash
mkdir -p .github/workflows
```

Copy this file to `.github/workflows/deploy.yml`:
- Source: `/opt/homeserver/docs/github-actions-workflow.yml`
- Destination: `.github/workflows/deploy.yml` (in your portal repo)

```bash
git add .github/workflows/deploy.yml
git commit -m "Add automated deployment"
git push
```

### 6. Fix Cloudflare Bot Protection (1 min)

**IMPORTANT:** GitHub Actions will be blocked unless you do this:

1. Go to **Cloudflare Dashboard**
2. Select your domain
3. **DNS** → Records
4. Find `deploy.mykyta-ryasny.dev`
5. Click the **orange cloud** to make it **gray (DNS only)**
6. Wait 2-3 minutes

---

## Test It! 🚀

Push any change to your portal repository:

```bash
git commit --allow-empty -m "Test webhook deployment"
git push
```

**Watch GitHub Actions:**
- Go to your repo → **Actions** tab
- Watch the workflow run
- Should see ✅ on all steps

**Watch Home Server:**
```bash
docker logs webhook -f
```

Should see:
```
🚀 Portal Deployment Started
⬇️  Pulling latest image...
▶️  Starting new container...
🏥 Waiting for health check...
✅ Deployment Successful!
```

---

## If Something Breaks

**Webhook not responding?**
```bash
docker logs webhook
docker ps | grep webhook
```

**Signature verification fails?**
```bash
# Check secret matches in both places
cat /opt/homeserver/scripts/webhooks/hooks.json | grep secret
# Compare with GitHub secret
```

**403 Forbidden from Cloudflare?**
- Turn `deploy.mykyta-ryasny.dev` to DNS-only (gray cloud)

**Container won't pull image?**
```bash
# Test manually
docker pull ghcr.io/mykytaryasny/homeserver-portal:latest
```

---

## Current Status

Check everything is working:

```bash
# Webhook running?
docker ps | grep webhook

# Logs clean?
docker logs webhook --tail 20

# Caddy routing correct?
docker exec caddy curl -I http://webhook:9000/hooks/deploy-portal

# External access (from another machine)?
curl -I https://deploy.mykyta-ryasny.dev/hooks/deploy-portal
```

---

## Files You Need to Know

- **Webhook config:** `/opt/homeserver/scripts/webhooks/hooks.json`
- **Deploy script:** `/opt/homeserver/scripts/deploy/deploy-portal.sh`
- **Workflow template:** `/opt/homeserver/docs/github-actions-workflow.yml`
- **Full guide:** `/opt/homeserver/docs/WEBHOOK_SETUP_GUIDE.md`

---

## Summary

**What happens when you push code:**

1. GitHub Actions builds Docker image
2. Pushes to GHCR (GitHub Container Registry)
3. Calculates HMAC signature
4. Sends webhook POST to your server
5. Webhook verifies signature
6. Runs deploy script
7. Script pulls new image
8. Restarts container
9. Checks health
10. Success ✅ or rollback ❌

**That's it!** Your automated deployment is ready. 🎉

Read the full guide for advanced topics, troubleshooting, and security best practices.
