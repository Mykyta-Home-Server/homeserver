#!/bin/bash
# ============================================================================
# Home Server Backup Script
# ============================================================================
# Purpose: Automated backup of Docker volumes, configs, and secrets
# Schedule: Daily at 3 AM via cron
# Retention: 30 days
# ============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/opt/homeserver/backups"
PROJECT_DIR="/opt/homeserver"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homeserver_backup_${TIMESTAMP}.tar.gz"
RETENTION_DAYS=30

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${BACKUP_DIR}/backup.log"
}

log "================================"
log "Starting backup process"
log "================================"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Create temporary staging directory
STAGING_DIR=$(mktemp -d)
trap "rm -rf ${STAGING_DIR}" EXIT

log "Staging directory: ${STAGING_DIR}"

# ============================================================================
# Backup Database Dumps
# ============================================================================
log "Backing up databases..."

mkdir -p "${STAGING_DIR}/databases"

# PostgreSQL backup
if docker ps --format '{{.Names}}' | grep -q '^postgres-auth$'; then
    log "  - Backing up PostgreSQL database"
    docker exec postgres-auth pg_dumpall -U authelia_user > "${STAGING_DIR}/databases/postgres-dump.sql" 2>/dev/null || log "    ! PostgreSQL backup failed"
fi

# Redis backup
if docker ps --format '{{.Names}}' | grep -q '^redis-auth$'; then
    log "  - Backing up Redis data"
    docker exec redis-auth redis-cli --rdb /data/backup.rdb >/dev/null 2>&1 || true
    docker cp redis-auth:/data/dump.rdb "${STAGING_DIR}/databases/redis-dump.rdb" 2>/dev/null || log "    ! Redis backup failed"
fi

# ============================================================================
# Backup Configuration Directories (non-database data)
# ============================================================================
log "Backing up configuration directories..."

mkdir -p "${STAGING_DIR}/service-configs"

# Backup Authelia config (small files only, not database)
if [ -d "${PROJECT_DIR}/services/auth/authelia" ]; then
    log "  - Backing up Authelia configuration"
    cp -r "${PROJECT_DIR}/services/auth/authelia" "${STAGING_DIR}/service-configs/" 2>/dev/null || log "    ! Some files skipped"
fi

# Backup Grafana dashboards (if accessible)
if [ -d "${PROJECT_DIR}/services/monitoring/grafana" ]; then
    log "  - Backing up Grafana configuration"
    # Only backup config files, not the database
    mkdir -p "${STAGING_DIR}/service-configs/grafana"
    cp -r "${PROJECT_DIR}/services/monitoring/grafana"/*.{ini,yaml,yml} "${STAGING_DIR}/service-configs/grafana/" 2>/dev/null || log "    ! Some files skipped"
fi

# ============================================================================
# Backup Configuration Files
# ============================================================================
log "Backing up configuration files..."

mkdir -p "${STAGING_DIR}/config"

# Backup docker-compose files
cp -r "${PROJECT_DIR}/compose" "${STAGING_DIR}/config/" 2>/dev/null || log "  ! compose/ not found"
cp "${PROJECT_DIR}/docker-compose.yml" "${STAGING_DIR}/config/" 2>/dev/null || log "  ! docker-compose.yml not found"

# Backup environment files
cp "${PROJECT_DIR}/.env"* "${STAGING_DIR}/config/" 2>/dev/null || log "  ! No .env files found"

# ============================================================================
# Backup Secrets
# ============================================================================
log "Backing up secrets..."

if [ -d "${PROJECT_DIR}/secrets" ]; then
    mkdir -p "${STAGING_DIR}/secrets"
    cp -r "${PROJECT_DIR}/secrets"/* "${STAGING_DIR}/secrets/" 2>/dev/null || true
    # Ensure proper permissions
    chmod 600 "${STAGING_DIR}/secrets"/* 2>/dev/null || true
fi

# ============================================================================
# Create Final Archive
# ============================================================================
log "Creating final backup archive: ${BACKUP_NAME}"

cd "${STAGING_DIR}"
tar czf "${BACKUP_DIR}/${BACKUP_NAME}" .

# Calculate archive size
ARCHIVE_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
log "Backup completed: ${ARCHIVE_SIZE}"

# ============================================================================
# Cleanup Old Backups
# ============================================================================
log "Cleaning up backups older than ${RETENTION_DAYS} days..."

find "${BACKUP_DIR}" -name "homeserver_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

REMAINING_BACKUPS=$(find "${BACKUP_DIR}" -name "homeserver_backup_*.tar.gz" -type f | wc -l)
log "Remaining backups: ${REMAINING_BACKUPS}"

# ============================================================================
# Summary
# ============================================================================
log "================================"
log "Backup process completed successfully"
log "Backup file: ${BACKUP_NAME}"
log "Location: ${BACKUP_DIR}"
log "================================"

exit 0
