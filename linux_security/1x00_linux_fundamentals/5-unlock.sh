#!/bin/bash
chattr -i "$1" && rm -f "$1"
