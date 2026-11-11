# All flake checks of one system.
{
  self,
  lib,
  pkgs,
  system,
}:
let
  args = {
    inherit
      self
      lib
      pkgs
      system
      ;
    helpers = import ../nix/eval.nix { inherit lib; };
  };
in
# Every ../tests/<name>.nix is a runNixOSTest module; the grundschutz modules
# are injected here so tests do not need to know their origin.
lib.mapAttrs' (file: _: {
  name = lib.removeSuffix ".nix" file;
  value = pkgs.testers.runNixOSTest {
    imports = [ (../tests + "/${file}") ];
    extraBaseModules.imports = [ ../modules ];
  };
}) (builtins.readDir ../tests)
// import ./assertions.nix args
// import ./eval.nix args
// import ./repo.nix args
