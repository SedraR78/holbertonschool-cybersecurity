#!/bin/bash
ss -ltnp4 2>/dev/null | grep ":$1 " | sed -n 's/.*users:((\"\([^\"]*\)\".*/\1/p'
