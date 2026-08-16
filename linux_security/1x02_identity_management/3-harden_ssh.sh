#!/bin/bash
CONFIG="${1:-/etc/ssh/sshd_config}"
BACKUP="${CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"

cp "$CONFIG" "$BACKUP"
sed -i -E '/^[[:space:]]*#?[[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)[[:space:]]/Id' "$CONFIG"
sed -i '1i PermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes' "$CONFIG"

if sshd -t -f "$CONFIG"; then
	systemctl reload ssh 2>/dev/null || systemctl reload sshd
	echo "SSH hardened and reloaded."
else
	cp "$BACKUP" "$CONFIG"
	echo "Validation failed. Config restored from $BACKUP" >&2
	exit 1
fi
