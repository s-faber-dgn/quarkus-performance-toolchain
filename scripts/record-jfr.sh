#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_pid "${1:-}"
pid="$1"
duration="${2:-60}"
output="$ARTIFACT_DIR/recording-${pid}-$(date +%Y%m%d-%H%M%S).jfr"
jcmd "$pid" JFR.start name=performance settings=profile duration="${duration}s" filename="$output" disk=true
echo "Recording started; output: $output"

