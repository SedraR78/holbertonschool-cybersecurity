#!/bin/bash
chgrp "$2" "$1" && chmod 2750 "$1" && printf '%s/*.log {\n    daily\n    rotate 7\n    missingok\n    notifempty\n    create 0640 root %s\n}\n' "$1" "$2" > /etc/logrotate.d/app
