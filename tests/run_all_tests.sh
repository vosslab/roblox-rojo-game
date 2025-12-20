#!/usr/bin/env bash
#set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "==> Selene"
"${SCRIPT_DIR}/run-selene.sh"

echo "==> StyLua"
"${SCRIPT_DIR}/run-stylua.sh"

echo "==> Lune"
"${SCRIPT_DIR}/run-lune-tests.sh"
