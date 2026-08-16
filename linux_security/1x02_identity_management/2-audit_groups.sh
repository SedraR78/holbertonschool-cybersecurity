#!/bin/bash
PASSWD_FILE="${1:-/etc/passwd}"
RISKY_GROUPS="disk docker shadow"

while IFS=: read -r username _ uid _; do
	[ "$uid" -ge 1000 ] || continue
	for group in $RISKY_GROUPS; do
		if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -qx "$group"; then
			echo "$username:$group"
		fi
	done
done < "$PASSWD_FILE"
