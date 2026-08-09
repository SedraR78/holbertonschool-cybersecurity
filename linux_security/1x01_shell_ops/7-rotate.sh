#!/bin/bash
[ -d "$1" ] || exit 1
mkdir -p "$1/backups"
for f in "$1"/*.log; do
    [ -e "$f" ] || continue
    if [ "$(stat -c%s "$f")" -gt 1024 ]; then
        gzip "$f" && mv "$f.gz" "$1/backups/"
    else
        echo "Skipping small file: $(basename "$f")"
    fi
done
