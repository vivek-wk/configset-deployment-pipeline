#!/usr/bin/env bash
# Step 10: Import Sequence Loader Script in Bash
# Executes strictly sequential import of Part 1 and Part 2 packages.
# Waits for SUCCESS status (PACK status & IPACK status) between each package.
# NO PARALLEL IMPORTS ALLOWED.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER" "1947")
ADAPTER_MODE="${1:-${ADAPTER_MODE:-rest_api}}"
DRY_RUN="${DRY_RUN:-false}"

# Sequential Package Definitions
PART_1_PACKS=(
    "ART"
    "ATS"
    "CVC"
    "ATS-OpenScience"
)

PART_2_PACKS=(
    "CRS-Navigatorenvr"
    "CRS-Walterenvr"
    "CRS-TCenvr"
    "CSH-Navigatorenvr"
    "CSH-Walterenvr"
    "CSH-Avanzerenvr"
    "CSH-TCenvr"
)

log_info "Step 10: Starting strictly sequential import sequence for EnvSet ${ENVSET_NUMBER}"

# Helper function to trigger and wait for single pack
import_and_verify_pack() {
    local pack="$1"
    local part_label="$2"

    log_info "---------------------------------------------------------"
    log_info "[${part_label}] Triggering import for package: '${pack}'"
    log_info "---------------------------------------------------------"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Simulating import execution for '${pack}'"
        log_success "[DRY-RUN] '${pack}' status: SUCCESS"
        return 0
    fi

    # Trigger import script on remote host / local script
    IMPORT_CMD="/apps/content_ji2a/ipackages/i2a/bin/import_pack.sh --envset ${ENVSET_NUMBER} --pack '${pack}'"
    execute_cmd "$IMPORT_CMD" || log_warn "Import trigger returned warning. Polling status..."

    # Poll status until SUCCESS
    MAX_ATTEMPTS=30
    POLL_INTERVAL=10
    ATTEMPT=1

    while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
        log_info "Polling status for '${pack}' (Attempt ${ATTEMPT}/${MAX_ATTEMPTS})..."
        STATUS=$("${SCRIPT_DIR}/validate_import_status.sh" "$pack" "$ADAPTER_MODE")

        if [ "$STATUS" = "SUCCESS" ]; then
            log_success "Package '${pack}' import SUCCESS confirmed!"
            return 0
        elif [ "$STATUS" = "FAILED" ]; then
            log_error "Package '${pack}' import FAILED!"
            return 1
        fi

        sleep "$POLL_INTERVAL"
        ATTEMPT=$((ATTEMPT + 1))
    done

    log_error "Timed out waiting for '${pack}' import status!"
    return 1
}

# Execute Part 1
log_info "========================================================="
log_info "EXECUTING SEQUENTIAL IMPORT SEQUENCE: PART 1"
log_info "========================================================="
for pack in "${PART_1_PACKS[@]}"; do
    import_and_verify_pack "$pack" "Part 1"
done

# Execute Part 2
log_info "========================================================="
log_info "EXECUTING SEQUENTIAL IMPORT SEQUENCE: PART 2"
log_info "========================================================="
for pack in "${PART_2_PACKS[@]}"; do
    import_and_verify_pack "$pack" "Part 2"
done

save_state_var "STEP10_IMPORT_SEQUENCE" "SUCCESS"
log_success "Step 10: All Part 1 and Part 2 import packages completed with SUCCESS status."
