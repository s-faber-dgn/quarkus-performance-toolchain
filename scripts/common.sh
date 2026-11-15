#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/artifacts}"
mkdir -p "$ARTIFACT_DIR"
require_pid() {
  if [[ $# -lt 1 || ! "$1" =~ ^[0-9]+$ ]]; then echo "Usage: $0 <java-pid> [options...]" >&2; exit 2; fi
  if ! kill -0 "$1" 2>/dev/null; then echo "No process with PID $1" >&2; exit 1; fi
  if ! command -v jcmd >/dev/null 2>&1; then echo "jcmd not found; use a full JDK and put its bin directory in PATH" >&2; exit 1; fi
}

