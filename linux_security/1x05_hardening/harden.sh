#!/bin/bash
# harden.sh - STIG-2024 compliance engine

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly CONFIG_FILE="${SCRIPT_DIR}/config/harden.cfg"
readonly LOG_FILE="/var/log/hardening.log"

# --- Fail-safe: root required ---
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR: this script must be run as root" >&2
	exit 1
fi

# --- Logger ---
log() {
	local level="$1" message="$2"
	printf '[%s] [%s] %s\n' "$(date -u +%FT%TZ)" "$level" "$message" >> "$LOG_FILE"
	printf '[%s] %s\n' "$level" "$message"
}

touch "$LOG_FILE"
chmod 640 "$LOG_FILE"
chown root:root "$LOG_FILE"

log "INFO" "Hardening framework initialized"

# --- Load configuration ---
[ -f "$CONFIG_FILE" ] || { log "ERROR" "Config not found: $CONFIG_FILE"; exit 1; }
# shellcheck source=/dev/null
. "$CONFIG_FILE"
log "INFO" "Configuration loaded"

# --- Load libraries ---
for lib in "${SCRIPT_DIR}"/lib/*.sh; do
	# shellcheck source=/dev/null
	. "$lib"
	log "INFO" "Loaded module: $(basename "$lib")"
done

# --- Orchestration ---
harden_network
harden_ssh
harden_identity
harden_system

generate_report

log "INFO" "Hardening completed"
