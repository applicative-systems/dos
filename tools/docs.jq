# Renders the module documentation (flake output `packages.<system>.docs`):
# README.md plus one <ID>.md per control of every group that has a module
# (KONF): module details where there is one, otherwise why there is none.
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

  def byId: sort_by(split(".") | .[0], (.[1:] | map(tonumber)));
  def status($id): $map[$id].status // "unmapped";
  # heading of the rationale section and fallback text, per status
  def why($st): {
      implemented: ["Our interpretation", "No rationale recorded in `mapping/mapping.json`."],
      partial: ["Our interpretation", "No rationale recorded in `mapping/mapping.json`."],
      planned: ["Plan", "Not implemented yet; no plan recorded."],
      manual: ["Why there is no module", "Left to the operator; no reason recorded."],
      "not-applicable": ["Why it does not apply", "No reason recorded."],
      deferred: ["Why it is deferred", "No reason recorded."],
      unmapped: ["Not triaged", "This requirement has not been assessed yet."]
    }[$st];
  def legend: [
    "| Status | Meaning |",
    "|---|---|",
    "| implemented | a module enforces the requirement |",
    "| partial | a module enforces part of it; the page says what is missing |",
    "| planned | a module is planned, not written yet |",
    "| manual | organizational or site-specific; no module can check it |",
    "| not-applicable | does not apply to NixOS servers (e.g. mobile devices) |",
    "| deferred | belongs in a role- or application-specific module, not here |",
    "| unmapped | not assessed yet |"
  ];

  ($facts.declared | byId) as $declared
  # every control (no sub-controls) of the groups that have a module
  | ($declared | map($ctl[.].group) | unique) as $groups
  | ($ctl | to_entries | map(.value | select((.group | IN($groups[])) and (.id | test("^[A-Z]+\\.[0-9]+\\.[0-9]+$"))) | .id) | byId) as $ids

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
            "| Status | \(status($id)) |"
          ]
          + ( if $declared | index($id) | not then
                [ "", "## \(why(status($id))[0])", "", ($mp.rationale // why(status($id))[1]) ]
              else [
            "| Module | \($mp.modules // [] | paths) |",
            "| Tests | \($mp.tests // [] | paths) |",
            "| Profiles | \(inProfiles($id) | if length == 0 then "none" else map("`\(.)`") | join(", ") end) |",
            "",
            "## \(why(status($id))[0])",
            "",
            ($mp.rationale // why(status($id))[1]),
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
      "One page per requirement of the groups \($groups | join(", ")), with the original BSI text.",
      "Requirements with a module say what we enforce and list its options; every module has the options `enable` and `exempt` (a documented reason to deviate).",
      "The others say why there is no module (yet).",
      "",
      "Status counts: \([$ids[] | status(.)] | group_by(.) | map("\(.[0]) \(length)") | join(", ")).",
      ""
    ]
    + legend
    + [
      "",
      "| ID | Title | Level | Status |",
      "|---|---|---|---|"
    ]
    + ($ids | map(. as $id | $ctl[$id] as $c
        | "| [\($id)](\(page($id))) | \($c.title) | \(prop($c; "sec_level")) | \(status($id)) |"))
    + attribution | join("\n")) }
