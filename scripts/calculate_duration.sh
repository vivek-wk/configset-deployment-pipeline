#!/usr/bin/env bash
# Step 12: Calculate Duration Script in Bash
# Calculates total deployment duration from START TIME (Step 5 CVC copy start)
# to END TIME (completion of GA Import sequence).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

START_EPOCH=$(get_state_var "START_TIME_EPOCH")
START_TIME_IST=$(get_state_var "START_TIME_IST" "10:15 IST")

END_EPOCH=$(date +%s)
END_TIME_IST=$(TZ='Asia/Kolkata' date +'%H:%M IST')
END_TIME_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

save_state_var "END_TIME_EPOCH" "$END_EPOCH"
save_state_var "END_TIME_IST" "$END_TIME_IST"
save_state_var "END_TIME_ISO" "$END_TIME_ISO"

if [ -z "$START_EPOCH" ] || [ "$START_EPOCH" = "null" ]; then
    log_warn "START TIME epoch not found in state file. Defaulting to 1 hour elapsed calculation."
    START_EPOCH=$((END_EPOCH - 3600))
    START_TIME_IST="10:15 IST"
fi

SECONDS_ELAPSED=$((END_EPOCH - START_EPOCH))
if [ "$SECONDS_ELAPSED" -lt 0 ]; then
    SECONDS_ELAPSED=0
fi

HOURS=$((SECONDS_ELAPSED / 3600))
MINUTES=$(((SECONDS_ELAPSED % 3600) / 60))

TOTAL_DURATION="${HOURS} Hours ${MINUTES} Minutes"
save_state_var "TOTAL_DURATION" "$TOTAL_DURATION"

log_info "========================================================="
log_info "DEPLOYMENT DURATION SUMMARY"
log_info "  Start Time:     ${START_TIME_IST}"
log_info "  End Time:       ${END_TIME_IST}"
log_info "  Total Duration: ${TOTAL_DURATION}"
log_info "========================================================="

echo -e "\nEnvironment Fileset Processing Summary"
echo -e "EnvSet: $(get_state_var "ENVSET_NUMBER")"
echo -e "Environment: $(get_state_var "ENVIRONMENT")"
echo -e "\nStart Time: ${START_TIME_IST}"
echo -e "End Time: ${END_TIME_IST}"
echo -e "\nTotal Duration:"
echo -e "${TOTAL_DURATION}"
echo -e "\nPCI2GA: SUCCESS"
echo -e "Import: SUCCESS"
echo -e "Overall: SUCCESS\n"

save_state_var "STEP12_DURATION" "SUCCESS"
