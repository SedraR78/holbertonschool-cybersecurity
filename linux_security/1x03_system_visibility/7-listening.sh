#!/bin/bash
ss -lnt4 | awk 'NR>1 { sub(/.*:/, "", $4); print $4 }' | sort -nu
