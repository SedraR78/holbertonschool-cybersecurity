#!/bin/bash
sudo ./0-audit_uid.sh /etc/passwd | tee 0-flag.txt
sudo ./1-audit_shells.sh /etc/passwd | tee 1-flag.txt
sudo ./2-audit_groups.sh /etc/passwd | tee 2-flag.txt
sudo ./5-audit_crypto.sh /etc/shadow | tee 5-flag.txt
