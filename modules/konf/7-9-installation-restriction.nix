# KONF.7.9 Einschränkung der Installation (normal-SdT, SOLLTE)
# Interpretation: on NixOS, software is installed through the Nix daemon
# (nix-env, nix profile, nix build). Only `allowedUsers` may connect to it
# (nix.settings.allowed-users), and neither allowed-users nor trusted-users may
# contain the wildcard "*". The system closure itself is read-only, so the root
# filesystem cannot be modified by unprivileged installs anyway.
# Status "partial": users can still download and run binaries in writable
# locations such as /home (see KONF.7.10 for noexec mounts).
import ../../lib/mkRequirement.nix {
  id = "KONF.7.9";

  options = lib: {
    allowedUsers = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      default = [
        "root"
        "@wheel"
      ];
      description = "Users (or @groups) allowed to use the Nix daemon, i.e. to install software.";
    };
  };

  apply =
    {
      config,
      lib,
      cfg,
      ...
    }:
    let
      noWildcard = name: l: {
        assertion = !config.nix.enable || !builtins.elem "*" l;
        message = "KONF.7.9: nix.settings.${name} must not contain \"*\" (is ${builtins.toJSON l}).";
      };
    in
    {
      # Priority 900 replaces the NixOS default [ "*" ] but loses against a plain
      # user definition; the assertions report a wildcard.
      nix.settings.allowed-users = lib.mkOverride 900 cfg.allowedUsers;

      assertions = [
        (noWildcard "allowed-users" config.nix.settings.allowed-users)
        (noWildcard "trusted-users" config.nix.settings.trusted-users)
      ];
    };
}
