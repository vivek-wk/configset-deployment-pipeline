#!/usr/bin/env bash
# Server Mapping Resolver Script for Wolters Kluwer Global Architecture
# Strictly maps the 2 production & staging EU PCI2GA servers.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ENVIRONMENT="${1:-${ENVIRONMENT:-STG}}"
ENVSET_NUMBER="${2:-${ENVSET_NUMBER:-1947}}"

ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:lower:]' '[:upper:]')
REGION="EU"

log_info "Resolving Server Mapping for Environment: ${ENVIRONMENT} (EU), EnvSet: ${ENVSET_NUMBER}"

TARGET_USER="cus01"
PCI2GA_BIN_PATH="/apps/cdc/wknl/pci2ga/bin"
PCI2GA_CONFIG_FILE="/apps/cdc/wknl/pci2ga/bin/config-wknl.xml"
PCI2GA_LOGS_PATH="/export/work/pci2ga/logs"
PICKED_UP_PATH="/export/work/pci2ga/picked-up"
IN_PROGRESS_PATH="/export/work/pci2ga/in-progress"
ENVFILES_PATH="/apps/content_ji2a/ipackages/i2a/Envfiles"

case "${ENVIRONMENT}" in
    STG)
        TARGET_HOSTNAME="wkgaeuslpci2ga01"
        TARGET_IP="10.73.144.124"
        CDC_REPORTER_URL="http://10.73.144.124:8080/cdc/packages"
        PCI2GA_URL="http://10.73.144.124:8085"
        CONFIG_PATH="/ftp/WKNL-LTR/input/staging/config/Env${ENVSET_NUMBER}"
        DELIVERY_PATH="/ftp/WKNL-LTR/input/staging/CMS/immediate_delivery"
        IMMEDIATE_PATH="/ftp/WKNL-LTR/input/staging/CMS/immediate"
        ;;
    PROD)
        TARGET_HOSTNAME="wkgaeuplpci2ga01"
        TARGET_IP="10.85.129.147"
        CDC_REPORTER_URL="http://10.85.129.147:8080/cdc/packages"
        PCI2GA_URL="http://10.85.129.147:8085"
        CONFIG_PATH="/ftp/WKNL-LTR/input/production/config/Env${ENVSET_NUMBER}"
        DELIVERY_PATH="/ftp/WKNL-LTR/input/production/CMS/immediate_delivery"
        IMMEDIATE_PATH="/ftp/WKNL-LTR/input/production/CMS/immediate"
        ;;
    *)
        log_error "Unsupported environment: '${ENVIRONMENT}'. Must be STG or PROD."
        exit 1
        ;;
esac

# Save state variables
save_state_var "ENVIRONMENT" "$ENVIRONMENT"
save_state_var "REGION" "$REGION"
save_state_var "ENVSET_NUMBER" "$ENVSET_NUMBER"
save_state_var "TARGET_HOSTNAME" "$TARGET_HOSTNAME"
save_state_var "TARGET_IP" "$TARGET_IP"
save_state_var "TARGET_USER" "$TARGET_USER"
save_state_var "CDC_REPORTER_URL" "$CDC_REPORTER_URL"
save_state_var "PCI2GA_URL" "$PCI2GA_URL"
save_state_var "CONFIG_PATH" "$CONFIG_PATH"
save_state_var "DELIVERY_PATH" "$DELIVERY_PATH"
save_state_var "IMMEDIATE_PATH" "$IMMEDIATE_PATH"
save_state_var "PCI2GA_BIN_PATH" "$PCI2GA_BIN_PATH"
save_state_var "PCI2GA_CONFIG_FILE" "$PCI2GA_CONFIG_FILE"
save_state_var "PCI2GA_LOGS_PATH" "$PCI2GA_LOGS_PATH"
save_state_var "PICKED_UP_PATH" "$PICKED_UP_PATH"
save_state_var "IN_PROGRESS_PATH" "$IN_PROGRESS_PATH"
save_state_var "ENVFILES_PATH" "$ENVFILES_PATH"

log_success "Server Mapping Resolved:"
echo "  - Hostname:         ${TARGET_HOSTNAME}"
echo "  - IP Address:       ${TARGET_IP}"
echo "  - CDC Reporter URL: ${CDC_REPORTER_URL}"
echo "  - PCI2GA URL:       ${PCI2GA_URL}"
echo "  - Config Path:      ${CONFIG_PATH}"
echo "  - Delivery Path:    ${DELIVERY_PATH}"
