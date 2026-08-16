#!/bin/bash
JUNIOR="${1:-junior}"
TARGET="/etc/sudoers.d/junior"
TMP=$(mktemp)

printf '%s ALL=(root) /usr/bin/systemctl restart apache2, /usr/bin/journalctl\n' "$JUNIOR" > "$TMP"

if visudo -c -f "$TMP" >/dev/null; then
	install -m 0440 -o root -g root "$TMP" "$TARGET"
	rm -f "$TMP"
	echo "Policy installed for $JUNIOR"
else
	rm -f "$TMP"
	echo "Invalid syntax, aborting." >&2
	exit 1
fi
