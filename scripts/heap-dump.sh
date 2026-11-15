#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_pid "${1:-}"
pid="$1"
output="$ARTIFACT_DIR/heap-${pid}-$(date +%Y%m%d-%H%M%S).hprof"
echo "Writing $output; this may pause the JVM and need substantial disk space."
jcmd "$pid" GC.heap_dump "$output"

