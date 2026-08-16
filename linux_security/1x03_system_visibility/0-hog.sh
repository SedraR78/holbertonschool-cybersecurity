#!/bin/bash
ps -eo pid,pcpu,comm --sort=-pcpu --no-headers | head -n 1 | awk '{ print $1, $3 }'
