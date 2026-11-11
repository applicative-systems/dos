# modules/<topic>/<n>-<m>-<slug>.nix -> nixosModules.<topic>-<n>-<m>
{ lib }:
lib.concatMapAttrs (
  topic: type:
  lib.optionalAttrs (type == "directory") (
    lib.concatMapAttrs (
      file: _:
      let
        m = builtins.match "([0-9]+-[0-9]+)-.*\\.nix" file;
      in
      lib.optionalAttrs (m != null) { "${topic}-${builtins.head m}" = ../modules + "/${topic}/${file}"; }
    ) (builtins.readDir (../modules + "/${topic}"))
  )
) (builtins.readDir ../modules)
