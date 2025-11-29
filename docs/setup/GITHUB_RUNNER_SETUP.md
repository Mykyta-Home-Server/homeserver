# Self-Hosted GitHub Actions Runner Setup

**Last Updated:** 2025-11-25

---

## 🎯 Why Self-Hosted Runner?

Running GitHub Actions on your own server eliminates the need for external API calls and Cloudflare configuration. Your workflows can directly access Docker and deploy services locally.

**Benefits:**
- ✅ No Cloudflare WAF configuration needed
- ✅ Faster deployments (no internet latency)
- ✅ Direct Docker socket access
- ✅ Free GitHub Actions minutes
- ✅ Can access internal services

---

## 📋 Setup Options

### Option 1: Docker Container Runner (Recommended)

**Advantages:** Isolated, easy to manage, can be included in your compose stack

**Disadvantages:** Slightly more complex setup for Docker-in-Docker

### Option 2: Native Runner

**Advantages:** Simpler Docker access, direct host access

**Disadvantages:** Runs on host system, not containerized

We'll use **Option 1** for consistency with your infrastructure.

---

## 🚀 Installation Steps

### Step 1: Get Runner Token from GitHub

1. Go to your repository: `https://github.com/MykytaRyasny/homeserver-portal`
2. Navigate to: **Settings → Actions → Runners**
3. Click: **New self-hosted runner**
4. Select: **Linux**
5. Copy the **registration token** (starts with `A...`)

### Step 2: Create Runner Compose File

Create `/opt/homeserver/compose/github-runner.yml`:

```yaml
services:
  github-runner:
    image: myoung34/github-runner:latest
    container_name: github-runner-portal
    restart: unless-stopped

    environment:
      # GitHub configuration
      - REPO_URL=https://github.com/MykytaRyasny/homeserver-portal
      - RUNNER_NAME=homeserver-runner
      - RUNNER_WORKDIR=/tmp/runner
      - RUNNER_GROUP=default
      - LABELS=self-hosted,linux,docker

      # Runner token (get from GitHub)
      - ACCESS_TOKEN=${GITHUB_RUNNER_TOKEN}

      # Timezone
      - TZ=Europe/Madrid

    volumes:
      # Docker socket - allows runner to execute docker commands
      - /var/run/docker.sock:/var/run/docker.sock

      # Persistent runner data
      - github-runner-data:/tmp/runner

    networks:
      - internal

    security_opt:
      - no-new-privileges:true

    labels:
      - "com.homeserver.group=automation"
      - "com.homeserver.description=GitHub Actions self-hosted runner"

volumes:
  github-runner-data:
    driver: local

networks:
  internal:
    external: true
```

### Step 3: Add Runner Token to .env

Edit `/opt/homeserver/.env`:

```bash
# GitHub Actions Runner
GITHUB_RUNNER_TOKEN=<your_registration_token>
```

**Note:** Registration tokens expire after 1 hour. For production, use a **Personal Access Token (PAT)** instead.

### Step 4: Start the Runner

```bash
# Add to docker-compose.yml includes
echo "  - compose/github-runner.yml" >> docker-compose.yml

# Start the runner
docker compose up -d github-runner

# Check logs
docker logs github-runner-portal -f
```

You should see:
```
Runner successfully added
Runner connection is good
Listening for Jobs
```

---

## 🔄 Simplified Workflow

With a self-hosted runner, your workflow becomes **much simpler**:

```yaml
name: Deploy to Home Server

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: self-hosted  # ← Uses your runner!

    steps:
      - name: Pull latest image
        run: docker pull ghcr.io/mykytaryasny/homeserver-portal:latest

      - name: Restart service
        run: |
          cd /opt/homeserver
          docker compose up -d portal

      - name: Verify deployment
        run: docker ps | grep portal
```

**That's it!** No API calls, no HMAC signatures, no Cloudflare WAF configuration needed.

---

## 🔐 Security Considerations

### Runner has Docker Socket Access

The runner can execute **any Docker command**, including:
- Starting/stopping containers
- Reading container data
- Modifying your infrastructure

**Mitigation:**
1. Only add runner to **your own repositories** (not public repos)
2. Use **branch protection** on main branch
3. **Require pull request reviews** before merging
4. **Monitor runner logs** regularly

### Network Isolation

The runner is on the `internal` network, so it can:
- ✅ Access Docker socket
- ✅ Access internal services
- ❌ Cannot be accessed from internet (secure)

---

## 🎯 Updated Deployment Workflow

Replace your current workflow with this simpler version:

```yaml
name: Deploy to Home Server

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-deploy:
    runs-on: self-hosted
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Deploy to homeserver
        run: |
          echo "�� Deploying portal service..."
          cd /opt/homeserver
          docker compose pull portal
          docker compose up -d portal

          echo "✅ Deployment complete!"
          docker ps | grep portal
```

**Benefits:**
- ✅ No API endpoint needed
- ✅ No HMAC signature calculation
- ✅ No Cloudflare WAF configuration
- ✅ Direct Docker access
- ✅ Much faster (no external API calls)

---

## 🔧 Using PAT Instead of Registration Token

Registration tokens expire after 1 hour. For permanent setup, use a **Personal Access Token (PAT)**:

### Step 1: Create PAT

1. Go to: https://github.com/settings/tokens
2. Click: **Generate new token (classic)**
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
4. Click: **Generate token**
5. Copy the token (starts with `ghp_...`)

### Step 2: Update .env

```bash
# Use PAT instead of registration token
GITHUB_RUNNER_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Step 3: Restart Runner

```bash
docker compose restart github-runner-portal
```

The runner will now stay registered permanently!

---

## 📊 Monitoring the Runner

### Check Runner Status

```bash
# View logs
docker logs github-runner-portal -f

# Check if runner is connected
docker logs github-runner-portal | grep "Listening for Jobs"

# Restart runner
docker compose restart github-runner-portal
```

### In GitHub

Go to: **Repository → Settings → Actions → Runners**

You should see your runner listed as "Idle" (green) when waiting for jobs.

---

## 🎉 Summary

You now have a **self-hosted GitHub Actions runner** that:

1. ✅ Runs on your server (no external API needed)
2. ✅ Has direct Docker access (fast deployments)
3. ✅ Bypasses all Cloudflare issues (runs internally)
4. ✅ Is secure (network isolated, only your repos)
5. ✅ Is simple (no complex authentication)

**Your deployment API is no longer needed!** The runner handles everything directly. 🚀

---

## 🗑️ Optional: Remove Deployment API

If you want to clean up the old deployment API:

```bash
# Stop and remove deployment API
docker compose stop deploy-api
docker compose rm deploy-api

# Remove from docker-compose.yml
# Comment out or remove: - compose/deployment.yml

# Keep the files for reference, but they're no longer needed
```

Your infrastructure is now **simpler and more reliable**! 🎉
