# KONF.8.1 Automatische Überprüfung (normal-SdT, SOLLTE)
# Interpretation: the system checks for updates on its own. On NixOS this is
# system.autoUpgrade, which periodically fetches the configured flake (or
# channel) and switches to it. Deployments that push updates centrally (CI,
# colmena, deploy-rs) set the requirement exempt and name that process.
# Status "partial": autoUpgrade only finds updates that reach the flake's
# lock file; bumping inputs (e.g. a scheduled CI job) is up to the user.
# Notification of administrators is not covered.
import ../../lib/mkRequirement.nix {
  id = "KONF.8.1";
  apply =
    { config, ... }:
    {
      assertions = [
        {
          assertion = config.system.autoUpgrade.enable;
          message = "KONF.8.1: system.autoUpgrade.enable must be true (or set grundschutz.requirements.\"KONF.8.1\".exempt and describe how updates are rolled out).";
        }
      ];
    };
}
