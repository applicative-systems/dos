# KONF.7.15 Lokale Firewall (normal-SdT, SOLLTE)
# Interpretation: host firewall enabled. Outbound filtering is NOT enforced
# (status "partial" in mapping/mapping.json); users must define allowlists.
import ../../lib/mkRequirement.nix {
  id = "KONF.7.15";
  apply = { config, lib, ... }: {
    networking.firewall.enable = lib.mkDefault true;
    assertions = [{
      assertion = config.networking.firewall.enable;
      message = "KONF.7.15: networking.firewall.enable must be true (or set grundschutz.requirements.\"KONF.7.15\".exempt).";
    }];
  };
}
