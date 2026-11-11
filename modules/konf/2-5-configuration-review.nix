# KONF.2.5 Überprüfung der Systemkonfiguration (normal-SdT, SOLLTE)
# Interpretation: the NixOS configuration in git is the reference state, and the
# activated system closure is immutable. What has to be ensured is that a running
# system can be traced back to exactly one commit: system.configurationRevision
# must be set (visible via `nixos-version --configuration-revision`) and must not
# be a dirty working tree, unless `allowDirty` is set.
# Status "partial": mutable state outside the closure (/etc files not managed by
# NixOS, /var, imperative changes) is not compared against the reference.
import ../../lib/mkRequirement.nix {
  id = "KONF.2.5";

  options = lib: {
    allowDirty = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Accept a configuration revision of an uncommitted working tree
        (flake `dirtyRev`, ending in `-dirty`). Meant for development machines.
      '';
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
      rev = config.system.configurationRevision;
    in
    {
      assertions = [
        {
          assertion = rev != null;
          message = "KONF.2.5: system.configurationRevision must be set, e.g. `system.configurationRevision = self.rev or self.dirtyRev or null;` in the flake (or set grundschutz.requirements.\"KONF.2.5\".exempt).";
        }
        {
          assertion = rev == null || cfg.allowDirty || !lib.hasSuffix "-dirty" rev;
          message = "KONF.2.5: system.configurationRevision is ${rev}, built from an uncommitted working tree. Commit first or set grundschutz.requirements.\"KONF.2.5\".allowDirty.";
        }
      ];
    };
}
