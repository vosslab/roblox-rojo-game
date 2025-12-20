#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

if ! command -v stylua >/dev/null 2>&1; then
  echo "stylua is not installed or not on PATH."
  echo "Install: brew install stylua"
  exit 127
fi

cd "$REPO_ROOT"
exec stylua src
