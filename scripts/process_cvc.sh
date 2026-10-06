#!/usr/bin/env bash
# Step 5: Process CVC Packages Script in Bash
# Copies MCP_CF.0000config_CVC* and CF.0000_config_CVC* to immediate_delivery and records deployment START TIME.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

CONFIG_PATH=$(get_state_var "CONFIG_PATH")
DELIVERY_PATH=$(get_state_var "DELIVERY_PATH")
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 5: Locating CVC package files in: ${CONFIG_PATH}"

# Record deployment START TIME
START_EPOCH=$(date +%s)
START_TIME_IST=$(TZ='Asia/Kolkata' date +'%H:%M IST')
START_TIME_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

save_state_var "START_TIME_EPOCH" "$START_EPOCH"
save_state_var "START_TIME_IST" "$START_TIME_IST"
save_state_var "START_TIME_ISO" "$START_TIME_ISO"

log_success "Deployment START TIME recorded: ${START_TIME_IST} (${START_TIME_ISO})"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating copy of CVC packages from ${CONFIG_PATH} to ${DELIVERY_PATH}"
    save_state_var "STEP5_PROCESS_CVC" "SUCCESS"
    exit 0
fi

if [ ! -d "$DELIVERY_PATH" ]; then
    mkdir -p "$DELIVERY_PATH"
fi

FOUND_CVC=0
for pattern in "MCP_CF.0000config_CVC*" "CF.0000_config_CVC*" "*CVC*"; do
    for f in ${CONFIG_PATH}/${pattern}; do
        if [ -f "$f" ]; then
            log_info "Copying CVC package file: $(basename "$f") -> ${DELIVERY_PATH}/"
            cp -p "$f" "${DELIVERY_PATH}/"
            FOUND_CVC=$((FOUND_CVC + 1))
        fi
    done
    if [ "$FOUND_CVC" -gt 0 ]; then
        break
    fi
done

if [ "$FOUND_CVC" -eq 0 ]; then
    log_error "No CVC package files found in ${CONFIG_PATH}!"
    save_state_var "STEP5_PROCESS_CVC" "FAILED"
    exit 1
fi

save_state_var "STEP5_PROCESS_CVC" "SUCCESS"
log_success "Step 5: Processed ${FOUND_CVC} CVC package file(s) into ${DELIVERY_PATH}."
