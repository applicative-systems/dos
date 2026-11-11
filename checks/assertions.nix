# Evaluation-only: for every case in ./assertion-cases.nix, at least one
# assertion of the requirement must fire when the user contradicts it.
# Check names: "KONF.4.4/lockout" -> konf-4-4-lockout-assertion.
{
  self,
  lib,
  pkgs,
  system,
  helpers,
  ...
}:
lib.mapAttrs' (
  id: contradiction:
  let
    reqId = builtins.head (lib.splitString "/" id);
    eval = helpers.evalSystem system [
      self.nixosModules.default
      contradiction
      { grundschutz.requirements.${reqId}.enable = true; }
    ];
    failed = helpers.failedAssertions "${reqId}:" eval;
    name = "${lib.toLower (lib.replaceStrings [ "." "/" ] [ "-" "-" ] id)}-assertion";
  in
  lib.nameValuePair name (
    assert failed != [ ];
    pkgs.runCommand name { } "touch $out"
  )
) (import ./assertion-cases.nix { inherit lib; })
