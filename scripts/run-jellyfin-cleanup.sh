#!/bin/bash

# Wrapper script to run Jellyfin cleanup from a Docker container
# This allows the script to access Jellyfin's internal network

JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-09bceb2e9526496a9500bd0b4876d33c}"

docker run --rm \
    --network internal \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /opt/homeserver/scripts/jellyfin-cleanup.py:/app/cleanup.py:ro \
    -e JELLYFIN_URL="http://jellyfin:8096" \
    -e JELLYFIN_API_KEY="$JELLYFIN_API_KEY" \
    python:3.11-slim \
    bash -c "pip install -q requests && python3 /app/cleanup.py"
