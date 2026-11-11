# Renders the module documentation (flake output `packages.<system>.docs`):
# README.md plus one <ID>.md per requirement that has a module.
# Emits a stream of {file, text}; nix/packages.nix writes each one out.
# Usage: jq -c --slurpfile m mapping/mapping.json --slurpfile o options.json \
#   --slurpfile f facts.json -f tools/docs.jq catalog/Grundschutz++-resolved_catalog.json
#   $f[0]: { declared: [id], profiles: { <name>: [id] } }
$m[0] as $map
| $o[0] as $opts
| $f[0] as $facts
| [ .catalog.groups[] | . as $g | .. | objects
    | select(has("parts") and has("props")) | . + {group: $g.id, groupTitle: $g.title} ]
| map({key: .id, value: .}) | from_entries as $ctl

| def prop($c; $n): [$c.props[] | select(.name == $n) | .value] | first;
  # "{{ insert: param, konf.2.5-prm1 }}" -> the parameter's label, emphasized
  def params($c): . as $s
    | reduce ($c.params // [])[] as $p ($s; gsub("\\{\\{ *insert: *param, *\($p.id | gsub("\\."; "\\.")) *\\}\\}"; "_\($p.label)_"));
  def part($c; $n): [$c.parts[]? | select(.name == $n) | .prose] | first // "" | params($c);
  def quote: split("\n") | map(if . == "" then ">" else "> " + . end) | join("\n");
  def code: if test("\n") then "\n\n  ```nix\n" + (split("\n") | map("  " + .) | join("\n")) + "\n  ```" else " `\(.)`" end;
  def paths: if length == 0 then "none" else map("`\(.)`") | join(", ") end;
  def page($id): "\($id).md";
  def inProfiles($id): [$facts.profiles | to_entries[] | select(.value | index($id)) | .key];
  def header: [
    "<!--",
    ("SPDX-" + "FileCopyrightText: Bundesamt für Sicherheit in der Informationstechnik (BSI); the grundschutz-nixos contributors"),
    ("SPDX-" + "License-Identifier: CC-BY-SA-4.0"),
    "-->",
    ""
  ];
  def attribution: [
    "",
    "---",
    "",
    "Requirement text: BSI Grundschutz++ ([Stand-der-Technik-Bibliothek](https://github.com/BSI-Bund/Stand-der-Technik-Bibliothek)), CC BY-SA 4.0. The rest is our interpretation, not an official BSI statement."
  ];

  ($facts.declared | sort_by(split(".") | .[0], (.[1:] | map(tonumber)))) as $ids

  # one page per requirement
  | ( $ids[] as $id | $ctl[$id] as $c | ($map[$id] // {}) as $mp
      | [ $opts | to_entries[]
          | select(.value.loc[2] == $id and (.value.loc[3] | IN("enable", "exempt") | not)) ] as $own
      | { file: page($id),
          text: (header + [
            "# \($id) \($c.title)",
            "",
            "| | |",
            "|---|---|",
            "| Group | \($c.group): \($c.groupTitle) |",
            "| Level | \(prop($c; "sec_level")) |",
            "| Status | \($mp.status // "unmapped") |",
            "| Module | \($mp.modules // [] | paths) |",
            "| Tests | \($mp.tests // [] | paths) |",
            "| Profiles | \(inProfiles($id) | if length == 0 then "none" else map("`\(.)`") | join(", ") end) |",
            "",
            "## Our interpretation",
            "",
            ($mp.rationale // "No rationale recorded in `mapping/mapping.json`."),
            "",
            "## Usage",
            "",
            "```nix",
            "grundschutz.requirements.\"\($id)\".enable = true;",
            "",
            "# deviate explicitly; disables enforcement and emits a warning:",
            "grundschutz.requirements.\"\($id)\".exempt = \"<reason, e.g. a risk assessment reference>\";",
            "```",
            "",
            "Failed assertions of this requirement start with `\($id):`."
          ]
          + ( if ($own | length) == 0 then [] else
                ["", "## Options", ""]
                + ( $own | map(.value as $v
                    | "### `\($v.loc[3:] | join("."))`\n\n"
                      + ($v.description | rtrimstr("\n")) + "\n\n"
                      + "- Type: `\($v.type)`\n"
                      + "- Default:" + ($v.default.text // "none" | code)
                      + (if $v.example then "\n- Example:" + ($v.example.text | code) else "" end)
                      + "\n") )
              end )
          + [
            "",
            "## BSI requirement",
            "",
            "### Statement",
            "",
            (part($c; "statement") | quote),
            "",
            "### Guidance",
            "",
            (part($c; "guidance") | if . == "" then "None." else quote end)
          ]
          + attribution | join("\n")) } ),

  # index
  { file: "README.md",
    text: (header + [
      "# Grundschutz++ NixOS modules",
      "",
      "One page per requirement with a module: what we enforce, its options and the original BSI text.",
      "Every requirement has the options `enable` and `exempt` (a documented reason to deviate).",
      "See `docs/STATUS.md` in the repository for all \($ctl | keys | map(select(test("^[A-Z]+\\.[0-9]+\\.[0-9]+$"))) | length) catalog controls.",
      "",
      "| ID | Title | Level | Status |",
      "|---|---|---|---|"
    ]
    + ($ids | map(. as $id | $ctl[$id] as $c
        | "| [\($id)](\(page($id))) | \($c.title) | \(prop($c; "sec_level")) | \($map[$id].status // "unmapped") |"))
    + attribution | join("\n")) }
