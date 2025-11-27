#!/bin/bash

# Wrapper script to run Jellyseerr cleanup from a Docker container
# This allows the script to access Jellyseerr and Jellyfin's internal network

JELLYSEERR_API_KEY="${JELLYSEERR_API_KEY:-MTc2MzgxNzgxMzU0MTdhYjUwMTc1LTg3MjctNDdkMy05NDhmLWNiMDA5NmExMzU3Nw==}"
JELLYFIN_API_KEY="${JELLYFIN_API_KEY:-09bceb2e9526496a9500bd0b4876d33c}"

docker run --rm \
    --network internal \
    -v /opt/homeserver/scripts/jellyseerr-cleanup.py:/app/cleanup.py:ro \
    -e JELLYSEERR_URL="http://jellyseerr:5055" \
    -e JELLYSEERR_API_KEY="$JELLYSEERR_API_KEY" \
    -e JELLYFIN_URL="http://jellyfin:8096" \
    -e JELLYFIN_API_KEY="$JELLYFIN_API_KEY" \
    python:3.11-slim \
    bash -c "pip install -q requests && python3 /app/cleanup.py"
