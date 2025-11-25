#!/bin/bash
# ============================================================================
# Home Server Backup Restore Test Script
# ============================================================================
# Purpose: Verify backup integrity and test restore procedures
# Usage: ./restore-test.sh [backup-file.tar.gz]
# ============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/opt/homeserver/backups"
TEST_DIR="/tmp/homeserver-restore-test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# Parse Arguments
# ============================================================================

if [ $# -eq 0 ]; then
    # No argument provided, use the most recent backup
    BACKUP_FILE=$(ls -t "${BACKUP_DIR}"/homeserver_backup_*.tar.gz 2>/dev/null | head -1)
    if [ -z "${BACKUP_FILE}" ]; then
        log_error "No backup files found in ${BACKUP_DIR}"
        exit 1
    fi
    log_info "No backup specified, using most recent: $(basename ${BACKUP_FILE})"
else
    BACKUP_FILE="$1"
    if [ ! -f "${BACKUP_FILE}" ]; then
        log_error "Backup file not found: ${BACKUP_FILE}"
        exit 1
    fi
fi

# ============================================================================
# Display Backup Information
# ============================================================================

log_info "========================================"
log_info "Backup Restore Test"
log_info "========================================"
log_info "Backup file: $(basename ${BACKUP_FILE})"
log_info "Size: $(du -h ${BACKUP_FILE} | cut -f1)"
log_info "Created: $(stat -c %y ${BACKUP_FILE} 2>/dev/null || stat -f %Sm ${BACKUP_FILE})"
log_info ""

# ============================================================================
# Create Test Directory
# ============================================================================

log_info "Creating test directory: ${TEST_DIR}"
rm -rf "${TEST_DIR}"
mkdir -p "${TEST_DIR}"

# ============================================================================
# Test 1: Archive Integrity
# ============================================================================

log_info "Test 1: Verifying archive integrity..."
if tar -tzf "${BACKUP_FILE}" >/dev/null 2>&1; then
    log_info "  ✓ Archive is valid and can be extracted"
else
    log_error "  ✗ Archive is corrupted or invalid"
    exit 1
fi

# ============================================================================
# Test 2: Extract Archive
# ============================================================================

log_info "Test 2: Extracting archive..."
if tar -xzf "${BACKUP_FILE}" -C "${TEST_DIR}" 2>/dev/null; then
    log_info "  ✓ Archive extracted successfully"
else
    log_error "  ✗ Failed to extract archive"
    exit 1
fi

# ============================================================================
# Test 3: Verify Backup Contents
# ============================================================================

log_info "Test 3: Verifying backup contents..."

EXPECTED_DIRS=("config" "secrets")
ERRORS=0

for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "${TEST_DIR}/${dir}" ]; then
        log_info "  ✓ Found: ${dir}/"
    else
        log_warn "  ✗ Missing: ${dir}/"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check for database backups
if [ -d "${TEST_DIR}/databases" ]; then
    log_info "  ✓ Found: databases/"

    # Check PostgreSQL dump
    if [ -f "${TEST_DIR}/databases/postgres-dump.sql" ]; then
        SIZE=$(du -h "${TEST_DIR}/databases/postgres-dump.sql" | cut -f1)
        log_info "    ✓ PostgreSQL dump found (${SIZE})"
    else
        log_warn "    ✗ PostgreSQL dump missing"
        ERRORS=$((ERRORS + 1))
    fi

    # Check Redis dump
    if [ -f "${TEST_DIR}/databases/redis-dump.rdb" ]; then
        SIZE=$(du -h "${TEST_DIR}/databases/redis-dump.rdb" | cut -f1)
        log_info "    ✓ Redis dump found (${SIZE})"
    else
        log_warn "    ✗ Redis dump missing"
        ERRORS=$((ERRORS + 1))
    fi
else
    log_warn "  ✗ Missing: databases/"
    ERRORS=$((ERRORS + 1))
fi

# ============================================================================
# Test 4: Verify Configuration Files
# ============================================================================

log_info "Test 4: Verifying configuration files..."

CONFIG_FILES=(
    "config/docker-compose.yml"
    "config/compose/auth.yml"
    "config/compose/media.yml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "${TEST_DIR}/${file}" ]; then
        log_info "  ✓ Found: ${file}"
    else
        log_warn "  ✗ Missing: ${file}"
        ERRORS=$((ERRORS + 1))
    fi
done

# ============================================================================
# Test 5: Verify Secrets
# ============================================================================

log_info "Test 5: Verifying secrets..."

if [ -d "${TEST_DIR}/secrets" ]; then
    SECRET_COUNT=$(find "${TEST_DIR}/secrets" -type f | wc -l)
    log_info "  ✓ Found ${SECRET_COUNT} secret file(s)"

    # List secret files
    find "${TEST_DIR}/secrets" -type f -exec basename {} \; | while read secret; do
        log_info "    - ${secret}"
    done
else
    log_warn "  ✗ Secrets directory not found"
    ERRORS=$((ERRORS + 1))
fi

# ============================================================================
# Test 6: SQL Dump Validation
# ============================================================================

log_info "Test 6: Validating SQL dump syntax..."

if [ -f "${TEST_DIR}/databases/postgres-dump.sql" ]; then
    # Check if SQL file starts with valid PostgreSQL dump header
    if head -1 "${TEST_DIR}/databases/postgres-dump.sql" | grep -q "PostgreSQL\|--"; then
        log_info "  ✓ SQL dump has valid header"

        # Count statements
        STATEMENT_COUNT=$(grep -c "^CREATE\|^INSERT\|^ALTER" "${TEST_DIR}/databases/postgres-dump.sql" || true)
        log_info "  ✓ Found ${STATEMENT_COUNT} SQL statements"
    else
        log_warn "  ✗ SQL dump may be invalid"
        ERRORS=$((ERRORS + 1))
    fi
else
    log_warn "  ⊘ Skipping (no SQL dump found)"
fi

# ============================================================================
# Summary
# ============================================================================

log_info ""
log_info "========================================"
log_info "Test Summary"
log_info "========================================"
log_info "Test directory: ${TEST_DIR}"
log_info "Total size: $(du -sh ${TEST_DIR} | cut -f1)"

if [ ${ERRORS} -eq 0 ]; then
    log_info "${GREEN}✓ All tests passed!${NC}"
    log_info "Backup is valid and ready for restoration."
else
    log_warn "${YELLOW}⚠ ${ERRORS} warning(s) found${NC}"
    log_warn "Backup may be incomplete but could still be usable."
fi

log_info ""
log_info "Cleaning up test directory..."
rm -rf "${TEST_DIR}"
log_info "Done!"

exit 0
