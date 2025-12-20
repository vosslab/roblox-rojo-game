#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

if ! command -v selene >/dev/null 2>&1; then
  echo "selene is not installed or not on PATH."
  echo "Install: brew install selene"
  exit 127
fi

cd "$REPO_ROOT"
exec selene src
