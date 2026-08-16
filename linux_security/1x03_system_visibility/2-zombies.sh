#!/bin/bash
ps -eo pid,stat --no-headers | awk '$2 ~ /^Z/ { print $1 }'
