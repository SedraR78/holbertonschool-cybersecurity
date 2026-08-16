#!/bin/bash
grep segfault "$1" 2>/dev/null || grep segfault /var/log/messages 2>/dev/null
