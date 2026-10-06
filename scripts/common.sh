#!/usr/bin/env bash
# Common Utilities and Helper Functions for EnvSet Deployment Automation
# Standard: POSIX Bash compliance, strict error handling capability

set -euo pipefail

# ANSI Color Codes
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

# File paths
STATE_FILE="${STATE_FILE:-.deployment_state.env}"

log_info() {
    echo -e "${COLOR_BLUE}[INFO] $(date +'%Y-%m-%d %H:%M:%S') - ${1}${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS] $(date +'%Y-%m-%d %H:%M:%S') - ${1}${COLOR_RESET}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN] $(date +'%Y-%m-%d %H:%M:%S') - ${1}${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - ${1}${COLOR_RESET}" >&2
}

save_state_var() {
    local key="$1"
    local value="$2"
    touch "$STATE_FILE"
    if grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$STATE_FILE"
    else
        echo "${key}=\"${value}\"" >> "$STATE_FILE"
    fi
}

get_state_var() {
    local key="$1"
    local default_val="${2:-}"
    if [ -f "$STATE_FILE" ]; then
        local val
        val=$(grep "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"')
        if [ -n "$val" ]; then
            echo "$val"
            return 0
        fi
    fi
    echo "$default_val"
}

execute_cmd() {
    local cmd="$1"
    local dry_run="${DRY_RUN:-false}"
    local is_local="${RUN_LOCAL:-true}"

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Would execute: ${cmd}"
        return 0
    fi

    if [ "$is_local" = "true" ] || [ "${TARGET_HOSTNAME:-localhost}" = "localhost" ]; then
        log_info "Executing local command: ${cmd}"
        eval "$cmd"
    else
        log_info "Executing remote SSH command on ${TARGET_USER:-cus01}@${TARGET_IP}: ${cmd}"
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 "${TARGET_USER:-cus01}@${TARGET_IP}" "$cmd"
    fi
}

retry_cmd() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd="$*"

    local attempt=1
    until eval "$cmd"; do
        if [ "$attempt" -ge "$max_attempts" ]; then
            log_error "Command failed after ${attempt}/${max_attempts} attempts: ${cmd}"
            return 1
        fi
        log_warn "Attempt ${attempt}/${max_attempts} failed. Retrying in ${delay}s: ${cmd}"
        sleep "$delay"
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
    return 0
}
