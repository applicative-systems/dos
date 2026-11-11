# Cross-checks modules, mapping/mapping.json, assertion cases and the profile.
# Inputs (see the `consistency` check in checks/repo.nix):
#   $f[0]: { declared, profile, withAssertionCase, moduleFiles }
#   $m[0]: mapping/mapping.json
#   $c[0]: the BSI catalog
# Prints one line per violation; no output means consistent.
$f[0] as $f
| $m[0] as $m
| ([$c[0].catalog.groups[] | .. | objects | select(has("parts") and has("props"))
    | {key: .id, value: ([.props[] | select(.name == "sec_level") | .value] | first)}]
   | from_entries) as $level
| ([$m[] | (.modules // [])[]]) as $mapped
| (
    # every module file is referenced by the mapping
    ($f.moduleFiles[] | select(. as $p | $mapped | index($p) | not)
      | "module \(.) is not referenced in mapping/mapping.json"),

    # implemented/partial entries name a module, and that requirement exists
    ($m | to_entries[] | select(.value.status == "implemented" or .value.status == "partial")
      | if ((.value.modules // []) | length) == 0
        then "\(.key) is \(.value.status) but lists no module"
        elif (.key as $id | $f.declared | index($id) | not)
        then "\(.key) is \(.value.status) but no module declares grundschutz.requirements.\"\(.key)\""
        else empty end),

    # declared requirements are mapped as implemented/partial
    ($f.declared[] | select(($m[.].status // "") as $s | $s != "implemented" and $s != "partial")
      | "\(.) has a module but mapping status is \($m[.].status // "missing")"),

    # every requirement has a contradiction in assertionCases
    ($f.declared[] | select(. as $id | $f.withAssertionCase | index($id) | not)
      | "\(.) has no entry in checks/assertion-cases.nix"),

    # the normal-SdT profile enables every normal-SdT requirement
    ($f.declared[] | select($level[.] == "normal-SdT" and (. as $id | $f.profile | index($id) | not))
      | "\(.) (normal-SdT) is not enabled in profiles/konf-normal-sdt.nix"),

    # ... and nothing of another level
    ($f.profile[] | select($level[.] != "normal-SdT")
      | "\(.) (\($level[.])) is enabled in profiles/konf-normal-sdt.nix")
  )
