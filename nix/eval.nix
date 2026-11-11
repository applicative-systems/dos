# Evaluation helpers shared by checks and packages.
{ lib }:
{
  # A NixOS system of `modules` for `system`, without anything else.
  evalSystem =
    system: modules:
    lib.nixosSystem {
      modules = modules ++ [
        {
          system.stateVersion = "25.05";
          nixpkgs.hostPlatform = system;
        }
      ];
    };

  # Messages of the failed assertions of `eval` that start with `prefix`.
  failedAssertions =
    prefix: eval:
    map (a: a.message) (
      builtins.filter (a: !a.assertion && lib.hasPrefix prefix a.message) eval.config.assertions
    );

  # Path of a file of this repository relative to its root, e.g. "modules/konf/...".
  repoPath = p: lib.removePrefix "${toString ../.}/" (toString p);
}
