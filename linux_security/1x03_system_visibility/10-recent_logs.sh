#!/bin/bash
awk -v cutoff="$(date -d '30 minutes ago' '+%b %e %H:%M:%S')" '$0 ~ /sshd/ && substr($0,1,15) >= cutoff' "${1:-/var/log/auth.log}"
