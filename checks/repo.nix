# Checks of the repository itself: formatting, licensing, generated files and
# the consistency of modules, mapping, assertion cases and profile.
{
  self,
  lib,
  pkgs,
  system,
  helpers,
  ...
}:
{
  formatting = self.formatter.${system}.check self;

  inherit (self.packages.${system}) docs modules-markdown;

  status-up-to-date = pkgs.runCommand "status-up-to-date" { } ''
    diff ${../docs/STATUS.md} ${self.packages.${system}.status} \
      || { echo "docs/STATUS.md is stale: run tools/update-status.sh"; exit 1; }
    touch $out
  '';

  mapping-paths = pkgs.runCommand "mapping-paths" { nativeBuildInputs = [ pkgs.jq ]; } ''
    cd ${self}
    missing=$(jq -r '.[] | ((.modules // []) + (.tests // []))[]' mapping/mapping.json \
      | while read -r p; do [ -e "$p" ] || echo "$p"; done)
    [ -z "$missing" ] || { echo "mapping.json references missing files:"; echo "$missing"; exit 1; }
    touch $out
  '';

  reuse = pkgs.runCommand "reuse-lint" { nativeBuildInputs = [ pkgs.reuse ]; } ''
    cd ${self}
    reuse lint
    touch $out
  '';

  # see tools/consistency.jq for the rules
  consistency =
    let
      reqs =
        (helpers.evalSystem system [ self.nixosProfiles.konf-normal-sdt ]).config.grundschutz.requirements;
      facts = builtins.toFile "facts.json" (
        builtins.toJSON {
          declared = lib.attrNames reqs;
          profile = lib.attrNames (lib.filterAttrs (_: r: r.enable) reqs);
          withAssertionCase = lib.unique (
            map (k: builtins.head (lib.splitString "/" k)) (
              lib.attrNames (import ./assertion-cases.nix { inherit lib; })
            )
          );
          moduleFiles = map helpers.repoPath (
            lib.attrValues (import ../nix/requirement-modules.nix { inherit lib; })
          );
        }
      );
    in
    pkgs.runCommand "consistency" { nativeBuildInputs = [ pkgs.jq ]; } ''
      jq -n -r \
        --slurpfile f ${facts} \
        --slurpfile m ${../mapping/mapping.json} \
        --slurpfile c ${../catalog/Grundschutz++-resolved_catalog.json} \
        -f ${../tools/consistency.jq} > errors
      if [ -s errors ]; then cat errors; exit 1; fi
      touch $out
    '';
}
