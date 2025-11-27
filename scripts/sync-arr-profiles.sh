#!/bin/bash

# Sync Custom Formats from Radarr to Sonarr
# This script copies custom formats to keep both *arr apps in sync

echo "Syncing custom formats from Radarr to Sonarr..."
echo ""

docker run --rm \
    --network internal \
    -v /opt/homeserver/scripts/sync-arr-profiles.py:/app/sync.py:ro \
    python:3.11-slim \
    bash -c "pip install -q requests && python3 /app/sync.py"
