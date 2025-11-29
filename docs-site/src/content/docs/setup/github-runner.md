---
title: GitHub Runner Setup
description: Self-hosted GitHub Actions runner configuration
---

Guide for setting up a self-hosted GitHub Actions runner.

## Overview

A self-hosted runner allows you to run GitHub Actions workflows on your own infrastructure.

## Deployment

The runner is deployed via Docker Compose:

```yaml
services:
  github-runner:
    profiles: ["cicd", "all"]
    image: myoung34/github-runner:latest
    container_name: github-runner
    restart: unless-stopped
    environment:
      - REPO_URL=https://github.com/your-username/homeserver
      - RUNNER_TOKEN=${GITHUB_RUNNER_TOKEN}
      - RUNNER_NAME=homeserver-runner
      - RUNNER_WORKDIR=/tmp/runner/work
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

## Getting the Token

1. Go to GitHub repo → Settings → Actions → Runners
2. Click "New self-hosted runner"
3. Copy the token from the configuration command
4. Add to `.env`: `GITHUB_RUNNER_TOKEN=your_token`

## Start the Runner

```bash
docker compose --profile cicd up -d github-runner
```

## Verify

Check GitHub repo → Settings → Actions → Runners

The runner should show as "Idle" (green).

## Usage in Workflows

```yaml
jobs:
  deploy:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      # Your deployment steps
```
