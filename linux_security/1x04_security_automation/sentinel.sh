#!/bin/bash
# Sentinel - self-healing security agent

CONFIG="${1:-/opt/sentinel/sentinel.conf}"
[ -f "$CONFIG" ] || { echo "ERROR: config file not found: $CONFIG" >&2; exit 1; }
. "$CONFIG"

for var in SERVICES FILES_TO_WATCH ALLOWED_PORTS; do
	if ! declare -p "$var" >/dev/null 2>&1; then
		echo "ERROR: required variable $var is not defined" >&2
		exit 1
	fi
done

GOLDEN_DIR="${GOLDEN_DIR:-/var/backups/sentinel}"
LOG_FILE="${LOG_FILE:-/var/log/sentinel.log}"

log() {
	local component="$1" target="$2" status="$3" details="$4"
	local ts
	ts=$(date -u +%FT%TZ)
	printf '{"timestamp":"%s","component":"%s","target":"%s","status":"%s","details":"%s"}\n' \
		"$ts" "$component" "$target" "$status" "$details" | tee -a "$LOG_FILE"
}

check_services() {
	local svc
	for svc in "${SERVICES[@]}"; do
		if pgrep -f "$svc" >/dev/null 2>&1; then
			log "SERVICE" "$svc" "OK" "OK: $svc is running"
		else
			if eval "$svc" >/dev/null 2>&1 || systemctl start "$svc" >/dev/null 2>&1; then
				log "SERVICE" "$svc" "FIXED" "FIXED: Restarted $svc"
			else
				log "SERVICE" "$svc" "ALERT" "ALERT: Failed to start $svc"
			fi
		fi
	done
}

check_integrity() {
	local file gold live_hash gold_hash
	for file in "${FILES_TO_WATCH[@]}"; do
		gold="$GOLDEN_DIR/$(basename "$file").gold"
		[ -f "$gold" ] || { log "INTEGRITY" "$file" "ALERT" "ALERT: Golden copy missing for $file"; continue; }
		live_hash=$(md5sum "$file" 2>/dev/null | awk '{print $1}')
		gold_hash=$(md5sum "$gold" 2>/dev/null | awk '{print $1}')
		if [ "$live_hash" = "$gold_hash" ]; then
			log "INTEGRITY" "$file" "OK" "OK: $file integrity verified"
		else
			if cp "$gold" "$file"; then
				log "INTEGRITY" "$file" "FIXED" "FIXED: Restored $file"
			else
				log "INTEGRITY" "$file" "ALERT" "ALERT: Restore failed for $file"
			fi
		fi
	done
}

check_ports() {
	local port pid allowed a
	while read -r port; do
		[ -n "$port" ] || continue
		allowed=0
		for a in "${ALLOWED_PORTS[@]}"; do
			[ "$port" = "$a" ] && allowed=1 && break
		done
		[ "$allowed" -eq 1 ] && continue
		pid=$(ss -ltnp4 2>/dev/null | grep ":$port " | grep -o 'pid=[0-9]*' | head -n1 | cut -d= -f2)
		if [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null; then
			log "PORT" "$port" "ALERT" "ALERT: Killed rogue process on port $port"
		else
			log "PORT" "$port" "ALERT" "ALERT: Killed rogue process on port $port (kill failed)"
		fi
	done < <(ss -ltn4 2>/dev/null | awk 'NR>1 {sub(/.*:/,"",$4); print $4}' | sort -nu)
}

check_services
check_integrity
check_ports
