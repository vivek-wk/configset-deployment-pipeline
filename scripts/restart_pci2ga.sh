#!/usr/bin/env bash
# Step 4: Restart PCI2GA Service Script in Bash
# Executes ./srv-stop.sh, verifies process termination, kills lingering processes,
# executes ./srv-start.sh, and verifies running user is 'cus01'.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

BIN_PATH=$(get_state_var "PCI2GA_BIN_PATH" "/apps/cdc/wknl/pci2ga/bin")
TARGET_USER=$(get_state_var "TARGET_USER" "cus01")
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 4: Initiating PCI2GA service restart in: ${BIN_PATH}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating ./srv-stop.sh in ${BIN_PATH}"
    log_info "[DRY-RUN] Simulating pgrep check and kill -9 lingering process"
    log_info "[DRY-RUN] Simulating ./srv-start.sh in ${BIN_PATH}"
    log_info "[DRY-RUN] Simulating service verification for user '${TARGET_USER}'"
    save_state_var "STEP4_RESTART_PCI2GA" "SUCCESS"
    exit 0
fi

if [ ! -d "$BIN_PATH" ]; then
    log_error "PCI2GA bin directory not found: ${BIN_PATH}"
    save_state_var "STEP4_RESTART_PCI2GA" "FAILED"
    exit 1
fi

cd "$BIN_PATH"

# Step 4.1: Stop Service
log_info "Executing ./srv-stop.sh..."
if [ -f "./srv-stop.sh" ]; then
    ./srv-stop.sh || log_warn "./srv-stop.sh returned non-zero code. Verifying process status..."
else
    log_warn "./srv-stop.sh not found in ${BIN_PATH}. Checking active processes..."
fi

sleep 3

# Step 4.2: Verify Stopped & Kill Lingering Processes
LINGERING_PIDS=$(pgrep -f "pci2ga" || true)
if [ -n "$LINGERING_PIDS" ]; then
    log_warn "Lingering PCI2GA processes detected (PIDs: ${LINGERING_PIDS}). Sending kill -9..."
    echo "$LINGERING_PIDS" | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Step 4.3: Start Service
log_info "Executing ./srv-start.sh..."
if [ -f "./srv-start.sh" ]; then
    ./srv-start.sh
else
    log_error "./srv-start.sh not found in ${BIN_PATH}!"
    save_state_var "STEP4_RESTART_PCI2GA" "FAILED"
    exit 1
fi

sleep 5

# Step 4.4: Verify Process Running under cus01
PS_OUT=$(ps -ef | grep "pci2ga" | grep -v "grep" || true)

if [ -z "$PS_OUT" ]; then
    log_error "PCI2GA service failed to start! No process found."
    save_state_var "STEP4_RESTART_PCI2GA" "FAILED"
    exit 1
fi

RUNNING_USER=$(echo "$PS_OUT" | awk '{print $1}')
log_info "PCI2GA service is running under user: '${RUNNING_USER}'"

if [ "$RUNNING_USER" != "$TARGET_USER" ] && ! echo "$PS_OUT" | grep -q "$TARGET_USER"; then
    log_error "Service running under user '${RUNNING_USER}', expected '${TARGET_USER}'!"
    save_state_var "STEP4_RESTART_PCI2GA" "FAILED"
    exit 1
fi

save_state_var "STEP4_RESTART_PCI2GA" "SUCCESS"
log_success "Step 4: PCI2GA service successfully restarted and verified."
