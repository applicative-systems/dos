# Renders docs/STATUS.md: every catalog control joined with mapping/mapping.json.
# Usage: jq -r --slurpfile m mapping/mapping.json -f tools/status.jq catalog/Grundschutz++-resolved_catalog.json
def statuses: ["implemented", "partial", "planned", "manual", "not-applicable", "deferred", "unmapped"];
def esc: gsub("\\|"; "\\|") | gsub("\n"; " ");
def links: if length == 0 then "" else map("[`\(.)`](../\(.))") | join("<br>") end;

$m[0] as $map
| [ .catalog.groups[] | . as $g
    | [ .. | objects
        | select(has("parts") and has("props") and (.id | test("^[A-Z]+\\.[0-9]+\\.[0-9]+$"))) ]
    | map({
        g: $g.id, gt: $g.title, id: .id, title: .title,
        level: ([.props[] | select(.name == "sec_level") | .value] | first),
        st: ($map[.id].status // "unmapped"),
        mods: ($map[.id].modules // []),
        tests: ($map[.id].tests // []),
        why: ($map[.id].rationale // "")
      })
  ] | flatten as $rows
| ($rows | map(.id)) as $ids
| ($map | keys | map(select(. as $k | $ids | index($k) | not))) as $orphans
| ($rows | reduce .[] as $r ([]; if index($r.g) then . else . + [$r.g] end)) as $order
| def active: .st == "implemented" or .st == "partial" or .st == "planned";
  ($order | map(. as $gid | select($rows | any(.g == $gid and active)))) as $shown
  | ($order - $shown) as $hidden
  | def count(f): [$rows[] | select(f)] | length;
  def cells(f): [statuses[] as $s | count(f and (.st == $s)) | tostring] | join(" | ");

  "<!--",
  ("SPDX-" + "FileCopyrightText: Bundesamt für Sicherheit in der Informationstechnik (BSI); the grundschutz-nixos contributors"),
  ("SPDX-" + "License-Identifier: CC-BY-SA-4.0"),
  "-->",
  "",
  "# Requirement status",
  "",
  "Generated from `catalog/` (BSI Grundschutz++, CC BY-SA 4.0) and `mapping/mapping.json`. Do not edit; run `tools/update-status.sh`.",
  "Controls without a mapping entry are `unmapped` (not yet triaged). Only groups with something implemented, partial or planned get a table. This is our interpretation, not an official BSI statement.",
  "",
  "## Summary",
  "",
  "| Group | Title | Total | \(statuses | join(" | ")) |",
  "|---|---|---|\(statuses | map("---") | join("|"))|",
  ( $order[] as $gid | ($rows | map(select(.g == $gid)) | .[0]) as $grp
    | "| \($grp.g) | \($grp.gt) | \(count(.g == $gid)) | \(cells(.g == $gid)) |" ),
  "| **all** | | **\($rows | length)** | \(cells(true)) |",
  "",
  ( $shown[] as $gid | ($rows | map(select(.g == $gid))) as $grp
    | "## \($grp[0].g): \($grp[0].gt)",
      "",
      "| ID | Level | Status | Title | Modules | Tests | Notes |",
      "|---|---|---|---|---|---|---|",
      ( $grp[] | "| \(.id) | \(.level) | \(.st) | \(.title | esc) | \(.mods | links) | \(.tests | links) | \(.why | esc) |" ),
      "" ),
  ( if ($hidden | length) > 0 then
      "## Groups without a table",
      "",
      "These groups have no implemented, partial or planned control, so their controls are not listed individually (see the summary for counts): " + ($hidden | join(", ")) + ".",
      "The full list is in `catalog/`.",
      ""
    else empty end ),
  ( if ($orphans | length) > 0 then
      "## Mapping entries without catalog control", "",
      ($orphans[] | "- \(.)"), ""
    else empty end )
