#!/bin/bash
ls -l "$1" | awk 'NR>1 {print $3}' | sort | uniq -c | sort -rn | head -1 | awk '{print $1, $2}'
