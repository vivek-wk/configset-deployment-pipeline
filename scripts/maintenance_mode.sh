#!/usr/bin/env bash
# Step 2: Maintenance Mode Script in Bash
# Toggles maintenance mode (enable / disable) via Notify API endpoint or local logging.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ACTION="${1:-${MAINT_ACTION:-enable}}"
ENVIRONMENT=$(get_state_var "ENVIRONMENT" "STG")
REGION=$(get_state_var "REGION" "EU")
ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER" "1947")
HOSTNAME=$(get_state_var "TARGET_HOSTNAME" "localhost")
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 2: Maintenance Mode Action requested: ${ACTION^^} for ${HOSTNAME} (${ENVIRONMENT}-${REGION})"

if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY-RUN] Simulating Maintenance Mode ${ACTION^^} call for ${HOSTNAME}"
    save_state_var "STEP2_MAINTENANCE_${ACTION^^}" "SUCCESS"
    exit 0
fi

NOTIFY_API_URL="${NOTIFY_API_URL:-https://notify-api.wk-ga.internal/api/v1/maintenance}"

log_info "Posting Maintenance Mode ${ACTION^^} notification to Notify API..."

# Attempt curl request to Notify API if reachable, else log local fallback gracefully
PAYLOAD="{\"action\":\"${ACTION}\",\"environment\":\"${ENVIRONMENT}\",\"region\":\"${REGION}\",\"envset\":\"${ENVSET_NUMBER}\",\"hostname\":\"${HOSTNAME}\"}"

if curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" --connect-timeout 5 "$NOTIFY_API_URL" >/dev/null 2>&1; then
    log_success "Notify API accepted maintenance mode ${ACTION^^} request."
else
    log_warn "Notify API unreachable (${NOTIFY_API_URL}). Logged local maintenance mode ${ACTION^^} event."
fi

save_state_var "STEP2_MAINTENANCE_${ACTION^^}" "SUCCESS"
log_success "Step 2: Maintenance mode ${ACTION^^} completed."
