#!/usr/bin/env bash
# Automated Integration & Syntax Test Suite for EnvSet Automation Bash Scripts

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

export ENVIRONMENT="STG"
export ENVSET_NUMBER="1947"
export DRY_RUN="true"
export RUN_LOCAL="true"

echo "========================================================="
echo "Running Automated Bash Script Validation Suite (Dry-Run)"
echo "========================================================="

echo "[TEST 1] Server Mapping..."
"${SCRIPT_DIR}/server_mapping.sh" STG 1947

echo "[TEST 2] Validation..."
"${SCRIPT_DIR}/validate_envset.sh"

echo "[TEST 3] Maintenance Mode Enable..."
"${SCRIPT_DIR}/maintenance_mode.sh" enable

echo "[TEST 4] Configuration Update..."
"${SCRIPT_DIR}/update_pci2ga_config.sh"

echo "[TEST 5] Service Restart..."
"${SCRIPT_DIR}/restart_pci2ga.sh"

echo "[TEST 6] Process CVC..."
"${SCRIPT_DIR}/process_cvc.sh"

echo "[TEST 7] Monitor Transformation..."
"${SCRIPT_DIR}/monitor_transformation.sh" CVC 30

echo "[TEST 8] Process Remaining Packs..."
"${SCRIPT_DIR}/process_remaining_packs.sh"

echo "[TEST 9] Verify EnvFiles..."
"${SCRIPT_DIR}/verify_envfiles.sh"

echo "[TEST 10] Import Sequence Loader..."
"${SCRIPT_DIR}/load_import_packs.sh" rest_api

echo "[TEST 11] Status Validation Adapter..."
"${SCRIPT_DIR}/validate_import_status.sh" ART rest_api

echo "[TEST 12] Duration Calculation..."
"${SCRIPT_DIR}/calculate_duration.sh"

echo "[TEST 13] Maintenance Mode Disable..."
"${SCRIPT_DIR}/maintenance_mode.sh" disable

echo "[TEST 14] Teams Notification..."
"${SCRIPT_DIR}/teams_notification.sh" SUCCESS

echo "========================================================="
echo "SUCCESS: All 14 Bash script tests passed!"
echo "========================================================="
