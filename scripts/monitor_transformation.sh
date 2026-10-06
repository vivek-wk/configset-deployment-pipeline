#!/usr/bin/env bash
# Step 6: Monitor Transformation & Auto-Recovery Script in Bash
# Monitors /export/work/pci2ga/logs/pciTransformer.log for 'Delivery finished with status SUCCESS'.
# Triggers Auto-Recovery if log inactive for 30 minutes.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

PACK_NAME="${1:-CVC}"
TIMEOUT_MINUTES="${2:-30}"
TIMEOUT_SEC=$((TIMEOUT_MINUTES * 60))

TRANSFORMER_LOG=$(get_state_var "PCI2GA_LOGS_PATH" "/export/work/pci2ga/logs")"/pciTransformer.log"
SERVICE_LOG=$(get_state_var "PCI2GA_LOGS_PATH" "/export/work/pci2ga/logs")"/service.log"
PICKED_UP_PATH=$(get_state_var "PICKED_UP_PATH" "/export/work/pci2ga/picked-up")
IN_PROGRESS_PATH=$(get_state_var "IN_PROGRESS_PATH" "/export/work/pci2ga/in-progress")
CONFIG_PATH=$(get_state_var "CONFIG_PATH")
DELIVERY_PATH=$(get_state_var "DELIVERY_PATH")
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 6: Monitoring transformation for pack '${PACK_NAME}' in: ${TRANSFORMER_LOG}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating log monitoring for pack '${PACK_NAME}'"
    log_success "[DRY-RUN] Found log status: Delivery finished with status SUCCESS"
    save_state_var "STEP6_MONITOR_${PACK_NAME}" "SUCCESS"
    exit 0
fi

POLL_START=$(date +%s)
LAST_ACTIVITY=$(date +%s)
RECOVERY_ATTEMPTED=false

while true; do
    NOW=$(date +%s)
    ELAPSED=$((NOW - POLL_START))
    INACTIVITY=$((NOW - LAST_ACTIVITY))

    # Check transformer log
    if [ -f "$TRANSFORMER_LOG" ]; then
        LATEST_SUCCESS=$(tail -n 100 "$TRANSFORMER_LOG" | grep "Delivery finished with status SUCCESS" || true)
        if [ -n "$LATEST_SUCCESS" ]; then
            log_success "Transformation for pack '${PACK_NAME}' completed with status SUCCESS!"
            save_state_var "STEP6_MONITOR_${PACK_NAME}" "SUCCESS"
            exit 0
        fi

        # Update last activity if log size or timestamp changed
        LAST_ACTIVITY=$(date +%s)
    fi

    # Check for 30 minute inactivity timeout -> Auto Recovery
    if [ "$INACTIVITY" -ge "$TIMEOUT_SEC" ] && [ "$RECOVERY_ATTEMPTED" = "false" ]; then
        log_warn "Log inactive for $((TIMEOUT_SEC / 60)) minutes! Triggering Auto-Recovery..."

        # Step 6 Auto-Recovery: 1. Check service log
        if [ -f "$SERVICE_LOG" ]; then
            WARN_OUT=$(tail -n 50 "$SERVICE_LOG" | grep -iE 'WARN|ERROR|EXCEPTION' || true)
            if [ -n "$WARN_OUT" ]; then
                log_warn "Warnings detected in service log: ${WARN_OUT}"
            fi
        fi

        # Step 6 Auto-Recovery: 2. Clean picked up & in progress
        log_info "Removing files from picked-up (${PICKED_UP_PATH}) and in-progress (${IN_PROGRESS_PATH})..."
        rm -rf "${PICKED_UP_PATH:?}"/* "${IN_PROGRESS_PATH:?}"/* 2>/dev/null || true

        # Step 6 Auto-Recovery: 3. Restart PCI2GA
        log_info "Auto-Recovery: Restarting PCI2GA service..."
        "${SCRIPT_DIR}/restart_pci2ga.sh"

        # Step 6 Auto-Recovery: 4. Resubmit package
        log_info "Auto-Recovery: Resubmitting package '${PACK_NAME}'..."
        cp -p "${CONFIG_PATH}"/*"${PACK_NAME}"* "${DELIVERY_PATH}/" 2>/dev/null || true

        RECOVERY_ATTEMPTED=true
        LAST_ACTIVITY=$(date +%s)
        POLL_START=$(date +%s)

    elif [ "$ELAPSED" -gt $((TIMEOUT_SEC * 2)) ]; then
        log_error "Transformation monitor timed out after $((ELAPSED / 60)) minutes!"
        save_state_var "STEP6_MONITOR_${PACK_NAME}" "FAILED"
        exit 1
    fi

    sleep 10
done
