#!/bin/bash
# Install Sentinel as a systemd timer

set -e
INSTALL_DIR="/opt/sentinel"

mkdir -p "$INSTALL_DIR" /var/backups/sentinel
install -m 0750 sentinel.sh "$INSTALL_DIR/sentinel.sh"
install -m 0640 sentinel.conf "$INSTALL_DIR/sentinel.conf"

install -m 0644 sentinel.service /etc/systemd/system/sentinel.service
install -m 0644 sentinel.timer /etc/systemd/system/sentinel.timer

systemctl daemon-reload
systemctl enable --now sentinel.timer
systemctl status sentinel.timer --no-pager
