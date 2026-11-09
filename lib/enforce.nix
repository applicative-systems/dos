# Set option values at priority 900 and assert on the final value.
#
#   enforce {
#     inherit lib config;
#     id = "KONF.4.3";
#     items = [
#       { path = [ "services" "openssh" "settings" "PasswordAuthentication" ]; value = false; }
#       # custom predicate, e.g. "subset of an allowlist":
#       { path = [ ... ]; value = [ ... ]; ok = actual: ...; expect = "a subset of ..."; }
#       # conditional (must not change which keys exist, only their values):
#       { path = [ ... ]; value = false; when = !cfg.allowForwarding; }
#     ];
#   }
#
#       # beat a plain NixOS default (priority 100); use sparingly:
#       { path = [ ... ]; value = false; priority = 50; }
#
# Returns { settings, assertions }. Priority 900 beats NixOS module defaults
# but loses against a plain user definition; the assertion then reports it.
{
  lib,
  config,
  id,
  items,
}:
{
  settings = lib.mkMerge (
    map (
      i: lib.setAttrByPath i.path (lib.mkIf (i.when or true) (lib.mkOverride (i.priority or 900) i.value))
    ) items
  );

  assertions = map (
    i:
    let
      actual = lib.attrByPath i.path null config;
      ok = i.ok or (a: a == i.value);
      expect = i.expect or "equal to ${builtins.toJSON i.value}";
    in
    {
      assertion = !(i.when or true) || ok actual;
      message = "${id}: ${lib.concatStringsSep "." i.path} must be ${expect} (is ${builtins.toJSON actual}).";
    }
  ) items;
}
