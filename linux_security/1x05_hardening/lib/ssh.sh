#!/bin/bash
# shellcheck disable=SC2034

# sshd keeps the first value it finds, so insert at the top
set_ssh_option() {
	local key="$1" value="$2"
	sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]/Id" "$SSHD_CONFIG"
	sed -i "1i ${key} ${value}" "$SSHD_CONFIG"
}

harden_ssh() {
	log "INFO" "=== SSH ==="

	mkdir -p "$BACKUP_DIR"
	cp "$SSHD_CONFIG" "${BACKUP_DIR}/sshd_config.bak"

	set_ssh_option "PasswordAuthentication" "$SSH_PASSWORD_AUTH"
	set_ssh_option "PubkeyAuthentication" "$SSH_PUBKEY_AUTH"
	set_ssh_option "PermitRootLogin" "$SSH_PERMIT_ROOT"
	set_ssh_option "Port" "$SSH_PORT"

	if sshd -t 2>/dev/null; then
		log "INFO" "SSH configured on port ${SSH_PORT}"
		REPORT_SSH="$SSH_PORT"
	else
		cp "${BACKUP_DIR}/sshd_config.bak" "$SSHD_CONFIG"
		log "ERROR" "Invalid sshd_config, restored from backup"
		return 1
	fi
}
