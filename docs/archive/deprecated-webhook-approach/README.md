# Deprecated: Webhook-Based Deployment Approach

**Status:** ❌ DEPRECATED (Replaced November 2025)

**Reason:** This webhook-based deployment system has been replaced with a **GitHub Actions self-hosted runner** approach, which is simpler, more secure, and better integrated with the CI/CD pipeline.

---

## What Was This?

This directory contains documentation for the original deployment system that used:
- A custom Python FastAPI webhook receiver (`deploy-api`)
- HMAC signature verification
- Manual deployment scripts triggered by GitHub webhooks
- Multiple authentication layers (webhook secret, deployment token, homeserver key)

## Why Was It Replaced?

### Old Approach (Webhook)
```
GitHub → Webhook → FastAPI Server → Deployment Script → Docker Compose
```

**Problems:**
- ❌ Extra moving parts (webhook receiver service)
- ❌ More complex authentication setup
- ❌ Separate service to maintain and secure
- ❌ Required exposed API endpoint (even through Cloudflare)

### New Approach (Self-Hosted Runner)
```
GitHub Actions → Self-Hosted Runner → Docker Commands Directly
```

**Benefits:**
- ✅ Direct GitHub Actions integration
- ✅ No exposed endpoints needed
- ✅ Simpler authentication (GitHub manages it)
- ✅ One less service to maintain
- ✅ Better visibility in GitHub UI
- ✅ Can build and deploy in same workflow

---

## Current Deployment Architecture

See [GITHUB_RUNNER_SETUP.md](../../GITHUB_RUNNER_SETUP.md) for the current deployment system.

**Key Components:**
1. **GitHub Actions Runner** - Containerized runner in `services/github-runner/`
2. **Docker Socket Mount** - Runner has access to host Docker
3. **Direct Deployment** - Workflow pulls and restarts containers directly

**Workflow Location:**
- Repository: `Mykyta-Home-Server/homeserver-portal`
- File: `.github/workflows/deploy.yml`

---

## Files in This Archive

| File | Purpose |
|------|---------|
| `DEPLOYMENT_API.md` | Webhook API documentation |
| `DEPLOYMENT_API_GITHUB_WORKFLOW.yml` | GitHub Actions workflow using webhooks |
| `DEPLOYMENT_API_SECURITY.md` | Security model for webhook approach |
| `DEPLOYMENT_API_SUMMARY.md` | Quick reference |
| `DEPLOYMENT_COMPLETE_SETUP.md` | Full setup guide |
| `DEPLOYMENT_SECURITY_SUMMARY.md` | Security summary |
| `WEBHOOK_QUICK_START.md` | Quick start guide |
| `WEBHOOK_QUICK_TEST.md` | Testing guide |

---

## Migration Notes

If you ever need to reference the old system:

1. **Secrets Used:**
   - `WEBHOOK_SECRET` (HMAC verification) - removed
   - `DEPLOYMENT_TOKEN` (additional auth) - removed
   - `HOMESERVER_KEY` (Cloudflare WAF bypass) - may still be relevant

2. **Services Removed:**
   - `deploy-api` container
   - `services/deployment/app.py`
   - `compose/deployment.yml`

3. **Scripts Removed:**
   - `scripts/deploy/deploy-portal.sh`

---

**Last Updated:** 2025-11-25
**Archived By:** Claude (Session cleanup)
