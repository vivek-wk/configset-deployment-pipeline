#!/usr/bin/env bash
# Step 13: Teams Notification Script in Bash
# Formats and posts MS Teams deployment summary card via Webhook URL or displays on stdout.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

STATUS="${1:-${DEPLOYMENT_STATUS:-SUCCESS}}"
FAILED_STEP="${2:-}"
ERROR_MSG="${3:-}"

ENVSET_NUMBER=$(get_state_var "ENVSET_NUMBER" "1947")
ENVIRONMENT=$(get_state_var "ENVIRONMENT" "STG")
START_TIME=$(get_state_var "START_TIME_IST" "10:15 IST")
END_TIME=$(get_state_var "END_TIME_IST" "13:42 IST")
TOTAL_DURATION=$(get_state_var "TOTAL_DURATION" "3 Hours 27 Minutes")
WEBHOOK_URL="${TEAMS_WEBHOOK_URL:-}"
DRY_RUN="${DRY_RUN:-false}"

log_info "Step 13: Preparing Teams Notification (Status: ${STATUS})..."

if [ "$STATUS" = "SUCCESS" ]; then
    MESSAGE="Environment Fileset Processing\n\nEnvSet: ${ENVSET_NUMBER}\nEnvironment: ${ENVIRONMENT}\n\nStart Time: ${START_TIME}\nEnd Time: ${END_TIME}\n\nTotal Duration:\n${TOTAL_DURATION}\n\nPCI2GA:\nSUCCESS\n\nImport:\nSUCCESS\n\nOverall:\nSUCCESS"
else
    MESSAGE="Environment Fileset Processing - FAILED\n\nEnvSet: ${ENVSET_NUMBER}\nEnvironment: ${ENVIRONMENT}\n\nStart Time: ${START_TIME}\nEnd Time: ${END_TIME}\n\nFailed Step:\n${FAILED_STEP:-Pipeline Step}\n\nError:\n${ERROR_MSG:-Execution Error}\n\nSuggested Action:\nVerify server logs and check input package file availability.\n\nOverall:\nFAILED"
fi

log_info "Formatted Notification Message:"
echo -e "\n================ TEAMS SUMMARY ================"
echo -e "$MESSAGE"
echo -e "===============================================\n"

if [ "$DRY_RUN" = "true" ] || [ -z "$WEBHOOK_URL" ]; then
    log_info "[DRY-RUN/NO-WEBHOOK] Webhook post skipped. Payload output displayed above."
    save_state_var "STEP13_TEAMS_NOTIFICATION" "SKIPPED"
    exit 0
fi

# Send to MS Teams Webhook
PAYLOAD="{\"@type\":\"MessageCard\",\"@context\":\"http://schema.org/extensions\",\"summary\":\"EnvSet ${ENVSET_NUMBER} Processing - ${STATUS}\",\"text\":\"${MESSAGE}\"}"

if curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" --connect-timeout 10 "$WEBHOOK_URL" >/dev/null 2>&1; then
    log_success "MS Teams notification posted successfully."
    save_state_var "STEP13_TEAMS_NOTIFICATION" "SUCCESS"
else
    log_warn "MS Teams webhook post failed or timed out."
    save_state_var "STEP13_TEAMS_NOTIFICATION" "FAILED"
fi
