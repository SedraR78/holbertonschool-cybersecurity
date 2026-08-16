#!/bin/bash
lsof -Pn -iTCP:$1 -sTCP:LISTEN -t | head -n 1 | xargs -r ps -o comm= -p
