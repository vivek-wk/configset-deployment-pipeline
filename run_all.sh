#!/usr/bin/env bash
# Interactive Main Entry Point for EnvSet Integration Automation Script
# Prompts user for Environment (STG or PROD) and ConfigSet / EnvSet Number.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/common.sh

echo -e "${COLOR_CYAN}"
echo "========================================================================="
echo "       Wolters Kluwer Global Architecture - EnvSet Deployment            "
echo "========================================================================="
echo -e "${COLOR_RESET}"

# Interactive Prompting for Environment and ConfigSet Number
if [ -z "${ENVIRONMENT:-}" ]; then
    echo "Select Target Environment:"
    echo "  1) STG  (wkgaeuslpci2ga01 - 10.73.144.124)"
    echo "  2) PROD (wkgaeuplpci2ga01 - 10.85.129.147)"
    read -rp "Enter choice [1 or 2, default: 1]: " env_choice
    case "${env_choice}" in
        2) ENVIRONMENT="PROD" ;;
        *) ENVIRONMENT="STG" ;;
    esac
fi

if [ -z "${ENVSET_NUMBER:-}" ]; then
    read -rp "Enter ConfigSet / EnvSet Number (e.g., 1947): " input_envset
    if [ -z "$input_envset" ]; then
        log_error "ConfigSet / EnvSet number cannot be empty!"
        exit 1
    fi
    ENVSET_NUMBER="$input_envset"
fi

if [ -z "${DRY_RUN:-}" ]; then
    read -rp "Enable Dry-Run Mode? (y/N): " dry_choice
    case "${dry_choice}" in
        [yY][eE][sS]|[yY]) DRY_RUN="true" ;;
        *) DRY_RUN="false" ;;
    esac
fi

export ENVIRONMENT ENVSET_NUMBER DRY_RUN

log_info "Starting EnvSet Automation Script..."
log_info "  Target Environment: ${ENVIRONMENT}"
log_info "  ConfigSet Number:   ${ENVSET_NUMBER}"
log_info "  Dry-Run Mode:       ${DRY_RUN}"

# Cleanup Handler on Failure
cleanup_on_failure() {
    log_error "Script execution failed! Disabling maintenance mode..."
    "${SCRIPT_DIR}/scripts/maintenance_mode.sh" "disable" || true
}
trap cleanup_on_failure ERR

# Execute All Steps Sequentially
log_info "\n>>> STEP 0: Resolving Server Mapping..."
"${SCRIPT_DIR}/scripts/server_mapping.sh" "${ENVIRONMENT}" "${ENVSET_NUMBER}"

log_info "\n>>> STEP 1: Validating EnvSet Directory & Packages..."
"${SCRIPT_DIR}/scripts/validate_envset.sh"

log_info "\n>>> STEP 2: Enabling Maintenance Mode..."
"${SCRIPT_DIR}/scripts/maintenance_mode.sh" "enable"

log_info "\n>>> STEP 3: Updating PCI2GA Configuration..."
"${SCRIPT_DIR}/scripts/update_pci2ga_config.sh"

log_info "\n>>> STEP 4: Restarting PCI2GA Service..."
"${SCRIPT_DIR}/scripts/restart_pci2ga.sh"

log_info "\n>>> STEP 5: Processing CVC Packages & Recording Start Time..."
"${SCRIPT_DIR}/scripts/process_cvc.sh"

log_info "\n>>> STEP 6: Monitoring CVC Transformation Log..."
"${SCRIPT_DIR}/scripts/monitor_transformation.sh" "CVC" 30

log_info "\n>>> STEP 7: Processing Remaining Packs (ART & ATS)..."
"${SCRIPT_DIR}/scripts/process_remaining_packs.sh"

log_info "\n>>> STEP 8 & 9: Verifying EnvFiles & Creating EnvSet Folder..."
"${SCRIPT_DIR}/scripts/verify_envfiles.sh"

log_info "\n>>> STEP 10 & 11: Executing Sequential GA Import & Status Validation..."
"${SCRIPT_DIR}/scripts/load_import_packs.sh" "rest_api"

log_info "\n>>> STEP 12: Calculating Total Deployment Duration..."
"${SCRIPT_DIR}/scripts/calculate_duration.sh"

log_info "\n>>> STEP 2 Cleanup: Disabling Maintenance Mode..."
"${SCRIPT_DIR}/scripts/maintenance_mode.sh" "disable"

log_info "\n>>> STEP 13: Posting Deployment Summary Notification..."
"${SCRIPT_DIR}/scripts/teams_notification.sh" "SUCCESS"

log_success "\n========================================================================="
log_success "  EnvSet ${ENVSET_NUMBER} Integration Script Completed SUCCESSFULLY!  "
log_success "========================================================================="
