#!/bin/bash
# shellcheck disable=SC2034

set_sysctl() {
	local key="$1" value="$2"
	sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=/d" "$SYSCTL_CONF"
	echo "${key} = ${value}" >> "$SYSCTL_CONF"
}

harden_network() {
	log "INFO" "=== Network ==="

	mkdir -p "$FIREWALL_DIR"

	cat > "$FIREWALL_FILE" <<RULES
DEFAULT_INPUT=${DEFAULT_INPUT}
DEFAULT_OUTPUT=${DEFAULT_OUTPUT}
ALLOW_TCP=${SSH_PORT}
ALLOW_TCP=${ALLOW_HTTP}
ALLOW_TCP=${ALLOW_HTTPS}
RULES

	chmod 644 "$FIREWALL_FILE"
	log "INFO" "Firewall policy created: ports ${SSH_PORT}, ${ALLOW_HTTP}, ${ALLOW_HTTPS} ALLOWED"
	REPORT_FIREWALL="${SSH_PORT}, ${ALLOW_HTTP}, ${ALLOW_HTTPS}"

	set_sysctl "net.ipv4.ip_forward" "$IP_FORWARD"
	set_sysctl "net.ipv4.icmp_echo_ignore_all" "$ICMP_IGNORE"

	if sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1; then
		log "INFO" "Kernel parameters applied"
	else
		log "WARN" "sysctl reload failed, values written to $SYSCTL_CONF"
	fi
}
