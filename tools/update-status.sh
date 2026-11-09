#!/usr/bin/env bash
# Regenerates docs/STATUS.md from the catalog and mapping/mapping.json.
set -euo pipefail
cd "$(dirname "$0")/.."
git add -A docs tools mapping >/dev/null 2>&1 || true # flake only sees tracked files
out=$(nix build .#status --no-link --print-out-paths)
install -m 644 "$out" docs/STATUS.md
