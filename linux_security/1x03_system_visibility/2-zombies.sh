#!/bin/bash
ps -eo pid,state --no-headers | awk '$2 == "Z" { print $1 }'
