#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_pid "${1:-}"
pid="$1"
duration="${2:-30}"
event="${3:-cpu}"
case "$event" in cpu|alloc|lock) ;; *) echo "Event must be cpu, alloc, or lock" >&2; exit 2 ;; esac
command -v asprof >/dev/null || { echo "asprof not found; install async-profiler and put it in PATH" >&2; exit 1; }
output="$ARTIFACT_DIR/profile-${event}-${pid}-$(date +%Y%m%d-%H%M%S).html"
asprof -d "$duration" -e "$event" -f "$output" "$pid"
echo "$output"

