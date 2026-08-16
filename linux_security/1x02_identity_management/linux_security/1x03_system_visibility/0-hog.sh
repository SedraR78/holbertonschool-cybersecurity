#!/bin/bash
ps -eo pid,comm --sort=-%cpu --no-headers | head -n 1 | awk '{ print $1, $2 }'
