#!/bin/bash

# Media Cleanup Cron Job
# Runs every 5 minutes to remove missing items from Jellyfin and Jellyseerr databases

LOG_FILE="/opt/homeserver/logs/media-cleanup.log"
SCRIPT_DIR="/opt/homeserver/scripts"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run Jellyfin cleanup
echo "=== Jellyfin Cleanup started at $(date) ===" >> "$LOG_FILE"
"$SCRIPT_DIR/run-jellyfin-cleanup.sh" >> "$LOG_FILE" 2>&1
echo "=== Jellyfin Cleanup finished at $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Run Jellyseerr cleanup
echo "=== Jellyseerr Cleanup started at $(date) ===" >> "$LOG_FILE"
"$SCRIPT_DIR/run-jellyseerr-cleanup.sh" >> "$LOG_FILE" 2>&1
echo "=== Jellyseerr Cleanup finished at $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Keep only last 1000 lines of log file (prevent it from growing too large)
tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
