#!/bin/sh
# Cron entrypoint script - ensures cron jobs output to stdout

set -e

echo "=== Maintenance Cron Container Started ==="
echo "Current time: $(date)"
echo "Timezone: $(cat /etc/timezone 2>/dev/null || echo 'UTC')"
echo ""

# Install dependencies
echo "Installing dependencies..."
apk add --no-cache python3 py3-pip curl docker-cli tzdata > /dev/null 2>&1
cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime
echo 'Europe/Madrid' > /etc/timezone
pip3 install --break-system-packages requests > /dev/null 2>&1

echo "Dependencies installed"
echo "Current time after timezone: $(date)"
echo ""

# Copy crontab from source to proper location and load it
echo "Loading crontab..."
cp /crontab-source /tmp/crontab
crontab /tmp/crontab

echo ""
echo "Crontab loaded. Contents:"
crontab -l | grep -v "^#" | grep -v "^$"

echo ""
echo "Starting crond in foreground..."
echo "Cron jobs will execute and output will appear below"
echo "Log file: /var/log/cron.log"
echo ""

# Create log file
touch /var/log/cron.log

# Start cron in background and tail the log file
crond -f -l 2 &

# Tail the log file to stdout (this makes cron output visible in docker logs)
tail -f /var/log/cron.log
