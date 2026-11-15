#!/usr/bin/env bash
set -euo pipefail
command -v jcmd >/dev/null || { echo "jcmd not found; use a full JDK" >&2; exit 1; }
jcmd -l

