#!/bin/bash
find "$1" -maxdepth 1 -name "*.log" -print0 | xargs -0 -I{} mv {} {}.old
