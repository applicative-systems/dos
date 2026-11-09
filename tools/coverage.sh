#!/usr/bin/env bash
# Lists catalog controls (id, level, title) and whether mapping/mapping.json covers them.
set -euo pipefail
cd "$(dirname "$0")/.."
jq -r --slurpfile m mapping/mapping.json '
  [.catalog.groups[]|..|objects|select(has("parts") and has("props") and (.id|test("^[A-Z]+\\.[0-9]+\\.[0-9]+$")))]
  | .[] | [.id, ([.props[]|select(.name=="sec_level")|.value]|first), ($m[0][.id].status // "unmapped"), .title] | @tsv
' catalog/Grundschutz++-resolved_catalog.json
