#!/usr/bin/env bash
# Step 1: Validation Script in Bash
# Verifies EnvSet directory exists and mandatory content packages (CVC, ART, ATS) are present.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=$(get_state_var "CONFIG_PATH")
ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER")
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 1: Starting validation for EnvSet ${ENVSET_NUMBER} at: ${CONFIG_PATH}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating directory check and package verification for ${CONFIG_PATH}"
    log_success "[DRY-RUN] Directory ${CONFIG_PATH} exists."
    log_success "[DRY-RUN] Mandatory packages CVC, ART, ATS verified."
    save_state_var "STEP1_VALIDATION" "SUCCESS"
    exit 0
fi

# Check directory existence
if [ ! -d "$CONFIG_PATH" ]; then
    log_error "EnvSet directory does not exist: ${CONFIG_PATH}"
    save_state_var "STEP1_VALIDATION" "FAILED"
    exit 1
fi
log_success "Directory exists: ${CONFIG_PATH}"

# Mandatory package validation
MANDATORY_PACKAGES=("CVC" "ART" "ATS")
MISSING_PACKAGES=()

for pkg in "${MANDATORY_PACKAGES[@]}"; do
    MATCH_COUNT=$(find "$CONFIG_PATH" -maxdepth 1 -name "*${pkg}*" | wc -l)
    if [ "$MATCH_COUNT" -gt 0 ]; then
        log_success "Mandatory package '${pkg}' found (${MATCH_COUNT} files)."
    else
        log_error "Mandatory package '${pkg}' missing in ${CONFIG_PATH}!"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log_error "Validation failed! Missing mandatory packages: ${MISSING_PACKAGES[*]}"
    save_state_var "STEP1_VALIDATION" "FAILED"
    exit 1
fi

save_state_var "STEP1_VALIDATION" "SUCCESS"
log_success "Step 1: Validation passed successfully."
