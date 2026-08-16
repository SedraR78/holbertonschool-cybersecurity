#!/bin/bash
lsof -ti :$1 -sTCP:LISTEN | head -n 1 | xargs -r ps -o comm= -p
