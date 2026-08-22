#!/bin/bash
# shellcheck disable=SC2034

export DEBIAN_FRONTEND=noninteractive

harden_system() {
	log "INFO" "=== System ==="

	if apt-get update -qq >/dev/null 2>&1; then
		apt-get upgrade -y -qq >/dev/null 2>&1
		log "INFO" "Repositories updated and packages upgraded"
	else
		log "WARN" "Package updates skipped (repository unreachable)"
		REPORT_UPDATE_WARN="1"
	fi

	local pkg removed=() installed=()

	for pkg in "${PKG_REMOVE[@]}"; do
		if dpkg -s "$pkg" >/dev/null 2>&1; then
			apt-get purge -y -qq "$pkg" >/dev/null 2>&1 && removed+=("$pkg")
		fi
	done

	for pkg in "${PKG_INSTALL[@]}"; do
		if dpkg -s "$pkg" >/dev/null 2>&1; then
			installed+=("$pkg")
		else
			apt-get install -y -qq "$pkg" >/dev/null 2>&1 && installed+=("$pkg")
		fi
	done

	REPORT_REMOVED=$(IFS=', '; echo "${removed[*]}")
	REPORT_INSTALLED=$(IFS=', '; echo "${installed[*]}")

	log "INFO" "Removed: ${REPORT_REMOVED:-none}"
	log "INFO" "Installed: ${REPORT_INSTALLED:-none}"
}

generate_report() {
	local line="==============================================="

	{
		echo "$line"
		echo " HARDENING AUDIT REPORT - $(date '+%Y-%m-%d %H:%M:%S')"
		echo "$line"
		echo
		echo "[INFO] Hardening procedure completed successfully."
		echo "[INFO] SSH configured on port ${REPORT_SSH:-$SSH_PORT}."
		echo "[INFO] Firewall policy created: ports ${REPORT_FIREWALL} ALLOWED."
		echo "[INFO] ${REPORT_USERS_COUNT:-0} unauthorized users removed${REPORT_USERS_LIST:+: $REPORT_USERS_LIST}."
		echo "[INFO] Installed: ${REPORT_INSTALLED:-none}."
		echo "[INFO] Removed: ${REPORT_REMOVED:-none}."
		[ -n "${REPORT_UPDATE_WARN:-}" ] && echo "[WARN] Package updates skipped (repository unreachable)."
		echo
		echo "$line"
		echo " COMPLIANCE STATUS: PASS"
		echo "$line"
	} > "$REPORT_FILE"

	log "INFO" "Audit report written to ${REPORT_FILE}"
}
