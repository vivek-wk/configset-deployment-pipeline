#!/usr/bin/env bash
# Step 8 & 9: Verify EnvFiles & Create EnvSet Folder Script in Bash
# Verifies transformed files exist for CVC, ART, ATS in /apps/content_ji2a/ipackages/i2a/Envfiles,
# creates target directory Env<envset_number>, and moves files into place.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ENVFILES_BASE_PATH=$(get_state_var "ENVFILES_PATH" "/apps/content_ji2a/ipackages/i2a/Envfiles")
ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER" "1947")
TARGET_ENV_FOLDER="${ENVFILES_BASE_PATH}/Env${ENVSET_NUMBER}"
DRY_RUN="${DRY_RUN:-false}"

EXPECTED_PACKAGES=("CVC" "ART" "ATS")

log_info "Step 8 & 9: Verifying transformed EnvFiles in: ${ENVFILES_BASE_PATH}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating verification of EnvFiles for: ${EXPECTED_PACKAGES[*]}"
    log_info "[DRY-RUN] Simulating folder creation: ${TARGET_ENV_FOLDER}"
    log_info "[DRY-RUN] Simulating moving EnvFiles into ${TARGET_ENV_FOLDER}"
    save_state_var "STEP8_9_VERIFY_ENVFILES" "SUCCESS"
    exit 0
fi

if [ ! -d "$ENVFILES_BASE_PATH" ]; then
    log_error "EnvFiles base directory does not exist: ${ENVFILES_BASE_PATH}"
    save_state_var "STEP8_9_VERIFY_ENVFILES" "FAILED"
    exit 1
fi

# Step 8: Verify transformed files exist for CVC, ART, ATS
MISSING_PACKAGES=()
FOUND_FILES=()

for pkg in "${EXPECTED_PACKAGES[@]}"; do
    MATCHES=$(find "$ENVFILES_BASE_PATH" -maxdepth 1 -name "*${pkg}*" ! -name "Env*" || true)
    if [ -n "$MATCHES" ]; then
        log_success "Verified transformed EnvFile for '${pkg}'"
        for file in $MATCHES; do
            FOUND_FILES+=("$file")
        done
    else
        log_error "Missing transformed EnvFile for package '${pkg}' in ${ENVFILES_BASE_PATH}"
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log_error "Step 8 Failed! Missing transformed files for: ${MISSING_PACKAGES[*]}"
    save_state_var "STEP8_9_VERIFY_ENVFILES" "FAILED"
    exit 1
fi

# Step 9: Create target directory Env<envset_number>
log_info "Step 9: Creating target directory: ${TARGET_ENV_FOLDER}"
mkdir -p "$TARGET_ENV_FOLDER"

# Move generated files into target directory
for src_file in "${FOUND_FILES[@]}"; do
    filename=$(basename "$src_file")
    log_info "Moving ${filename} -> ${TARGET_ENV_FOLDER}/"
    mv "$src_file" "${TARGET_ENV_FOLDER}/"
done

save_state_var "STEP8_9_VERIFY_ENVFILES" "SUCCESS"
save_state_var "TARGET_ENV_FOLDER" "$TARGET_ENV_FOLDER"
log_success "Step 8 & 9: Transformed EnvFiles verified and moved to ${TARGET_ENV_FOLDER}."
