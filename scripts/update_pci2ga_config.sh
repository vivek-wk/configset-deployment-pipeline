#!/usr/bin/env bash
# Step 3: Update Configuration Script in Bash
# Backs up /apps/cdc/wknl/pci2ga/bin/config-wknl.xml, updates <environmentVersion> tag to ENV_CONF_<envset_number>.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CONFIG_FILE=$(get_state_var "PCI2GA_CONFIG_FILE" "/apps/cdc/wknl/pci2ga/bin/config-wknl.xml")
ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER" "1947")
DRY_RUN="${DRY_RUN:-false}"
TARGET_VERSION="ENV_CONF_${ENVSET_NUMBER}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${CONFIG_FILE}.bak_${TIMESTAMP}"

log_info "Step 3: Target configuration file: ${CONFIG_FILE}"
log_info "Step 3: Target environment version: ${TARGET_VERSION}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Would create backup at: ${BACKUP_PATH}"
    log_info "[DRY-RUN] Would update <environmentVersion> to ${TARGET_VERSION} in ${CONFIG_FILE}"
    save_state_var "STEP3_CONFIG_UPDATE" "SUCCESS"
    save_state_var "CONFIG_BACKUP_PATH" "${BACKUP_PATH}"
    exit 0
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "PCI2GA configuration file not found: ${CONFIG_FILE}"
    save_state_var "STEP3_CONFIG_UPDATE" "FAILED"
    exit 1
fi

# Step 3.1: Create Backup
log_info "Creating timestamped backup: ${BACKUP_PATH}"
cp -p "$CONFIG_FILE" "$BACKUP_PATH"
save_state_var "CONFIG_BACKUP_PATH" "${BACKUP_PATH}"

# Step 3.2: Inspect current version
PREV_VERSION=$(grep -oP '(?<=<environmentVersion>).*?(?=</environmentVersion>)' "$CONFIG_FILE" || echo "UNKNOWN")
log_info "Current <environmentVersion>: ${PREV_VERSION}"

# Step 3.3: Update tag in XML file
log_info "Updating <environmentVersion> to ${TARGET_VERSION}..."
sed -i -E "s|(<environmentVersion>).*?(</environmentVersion>)|\1${TARGET_VERSION}\2|g" "$CONFIG_FILE"

# Step 3.4: Verify update
NEW_VERSION=$(grep -oP '(?<=<environmentVersion>).*?(?=</environmentVersion>)' "$CONFIG_FILE" || echo "FAILED")
if [ "$NEW_VERSION" != "$TARGET_VERSION" ]; then
    log_error "Verification failed! Configuration tag is ${NEW_VERSION}, expected ${TARGET_VERSION}"
    save_state_var "STEP3_CONFIG_UPDATE" "FAILED"
    exit 1
fi

log_success "Audit Log: Config ${CONFIG_FILE} updated from ${PREV_VERSION} to ${TARGET_VERSION}. Backup: ${BACKUP_PATH}"
save_state_var "STEP3_CONFIG_UPDATE" "SUCCESS"
save_state_var "PREVIOUS_ENV_VERSION" "${PREV_VERSION}"
