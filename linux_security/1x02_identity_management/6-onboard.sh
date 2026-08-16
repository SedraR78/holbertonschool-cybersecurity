#!/bin/bash
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <username> <ssh-public-key>" >&2
	exit 1
fi

USERNAME="$1"
PUBKEY="$2"

id "$USERNAME" >/dev/null 2>&1 || useradd -m -s /bin/bash "$USERNAME"
passwd -l "$USERNAME"

HOME_DIR=$(getent passwd "$USERNAME" | cut -d: -f6)
SSH_DIR="$HOME_DIR/.ssh"

mkdir -p "$SSH_DIR"
echo "$PUBKEY" >> "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R "$USERNAME":"$USERNAME" "$SSH_DIR"
