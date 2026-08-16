#!/bin/bash
# Install Sentinel as a systemd timer

set -e
INSTALL_DIR="/opt/sentinel"

mkdir -p "$INSTALL_DIR" /var/backups/sentinel
cp sentinel.sh "$INSTALL_DIR/sentinel.sh"
cp sentinel.conf "$INSTALL_DIR/sentinel.conf"
chmod 0750 "$INSTALL_DIR/sentinel.sh"
chmod 0640 "$INSTALL_DIR/sentinel.conf"

cp sentinel.service /etc/systemd/system/sentinel.service
cp sentinel.timer /etc/systemd/system/sentinel.timer
chmod 0644 /etc/systemd/system/sentinel.service /etc/systemd/system/sentinel.timer

systemctl daemon-reload
systemctl enable --now sentinel.timer
systemctl status sentinel.timer --no-pager
