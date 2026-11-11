# KONF.8.2 Automatische Updates der Anwendung (normal-SdT, SOLLTE)
# Interpretation: applications on NixOS are part of the system closure, so
# automatic installation of their updates is system.autoUpgrade (the same
# mechanism as KONF.8.1, here also required to activate the update: either
# operation "switch", or "boot" with allowReboot).
# Status "partial": applications updated outside Nix (containers, language
# package managers, self-updating software) are not covered, and updates
# only arrive once the flake's lock file is bumped.
import ../../lib/mkRequirement.nix {
  id = "KONF.8.2";
  apply =
    { config, ... }:
    let
      au = config.system.autoUpgrade;
    in
    {
      assertions = [
        {
          assertion = au.enable && (au.operation == "switch" || au.allowReboot);
          message = "KONF.8.2: system.autoUpgrade must be enabled, and with operation \"boot\" also allowReboot, so that updates take effect (or set grundschutz.requirements.\"KONF.8.2\".exempt and describe how updates are rolled out).";
        }
      ];
    };
}
