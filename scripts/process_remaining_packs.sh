#!/usr/bin/env bash
# Step 7: Process Remaining Packs (ART, ATS) Script in Bash
# Copies ART and ATS packages sequentially to delivery path and monitors for SUCCESS status.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=$(get_state_var "CONFIG_PATH")
DELIVERY_PATH=$(get_state_var "DELIVERY_PATH")
DRY_RUN="${DRY_RUN:-false}"

REMAINING_PACKS=("ART" "ATS")

log_info "Step 7: Processing remaining mandatory packages: ${REMAINING_PACKS[*]}"

for pack in "${REMAINING_PACKS[@]}"; do
    log_info "--- Processing package: ${pack} ---"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Simulating copy and transformation for '${pack}'"
        continue
    fi

    # Locate package files
    FILES=$(find "$CONFIG_PATH" -maxdepth 1 -name "*${pack}*" || true)
    if [ -z "$FILES" ]; then
        log_error "No files found for package '${pack}' in ${CONFIG_PATH}!"
        save_state_var "STEP7_PROCESS_REMAINING_PACKS" "FAILED"
        exit 1
    fi

    for f in $FILES; do
        log_info "Copying ${pack} package file: $(basename "$f") -> ${DELIVERY_PATH}/"
        cp -p "$f" "${DELIVERY_PATH}/"
    done

    # Monitor transformation log for this package
    "${SCRIPT_DIR}/monitor_transformation.sh" "$pack" 30
done

save_state_var "STEP7_PROCESS_REMAINING_PACKS" "SUCCESS"
log_success "Step 7: Remaining packages (ART, ATS) successfully processed and transformed."
