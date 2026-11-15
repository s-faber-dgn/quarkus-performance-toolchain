#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_pid "${1:-}"
pid="$1"
for command_name in VM.command_line VM.flags GC.heap_info; do
  echo "== $command_name =="
  jcmd "$pid" "$command_name"
done
echo "== Thread.print (first 100 lines) =="
jcmd "$pid" Thread.print -l | sed -n '1,100p'

