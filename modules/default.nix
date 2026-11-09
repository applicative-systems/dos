# Imports every modules/<topic>/<n>-<m>-<slug>.nix. New requirement modules
# are picked up automatically.
{ lib, ... }:
{
  imports = lib.concatLists (
    lib.mapAttrsToList (
      topic: type:
      lib.optionals (type == "directory") (
        lib.mapAttrsToList (file: _: ./. + "/${topic}/${file}") (
          lib.filterAttrs (file: _: lib.hasSuffix ".nix" file) (builtins.readDir (./. + "/${topic}"))
        )
      )
    ) (builtins.readDir ./.)
  );
}
