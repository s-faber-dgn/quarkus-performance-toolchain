#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_pid "${1:-}"
output="$ARTIFACT_DIR/threads-${1}-$(date +%Y%m%d-%H%M%S).txt"
jcmd "$1" Thread.print -l > "$output"
echo "$output"

