# KONF.4.5 Zeitquellen (normal-SdT, SOLLTE)
# Interpretation: time sources are authorized by listing them explicitly in
# `allowedTimeServers`. networking.timeServers and systemd-timesyncd (NTP= and
# FallbackNTP=) are set to that list, and every enabled NTP client (timesyncd,
# chrony, ntpd) is asserted to use only listed servers. There is no default:
# enabling the requirement without a list fails evaluation.
# Status "partial": NTP servers handed out via DHCP (networkd UseNTP=, dhcpcd)
# are not suppressed, ntpd-rs with custom `settings.source` is not inspected,
# and authenticated NTP (NTS) is not enforced.
import ../../lib/mkRequirement.nix {
  id = "KONF.4.5";

  options = lib: {
    allowedTimeServers = lib.mkOption {
      type = lib.types.nullOr (lib.types.nonEmptyListOf lib.types.str);
      default = null;
      example = [
        "ntp1.example.org"
        "ntp2.example.org"
      ];
      description = "Authorized NTP servers. Must be set when the requirement is enabled.";
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
      allowed = if cfg.allowedTimeServers == null then [ ] else cfg.allowedTimeServers;
      # Priority 900 beats the NixOS defaults but not a plain user definition;
      # the assertions below report such deviations.
      set = lib.mkOverride 900 allowed;
      check = name: enabled: servers: {
        assertion = !enabled || servers == null || lib.all (s: builtins.elem s allowed) servers;
        message = "KONF.4.5: ${name} must be a subset of allowedTimeServers ${builtins.toJSON allowed} (is ${builtins.toJSON servers}).";
      };
      inherit (config.services) timesyncd chrony ntp;
    in
    {
      networking.timeServers = set;
      services.timesyncd.servers = set;
      services.timesyncd.fallbackServers = set;
      # chrony and ntpd default to networking.timeServers.

      assertions = [
        {
          assertion = cfg.allowedTimeServers != null;
          message = "KONF.4.5: grundschutz.requirements.\"KONF.4.5\".allowedTimeServers must list the authorized NTP servers.";
        }
        (check "networking.timeServers" true config.networking.timeServers)
        (check "services.timesyncd.servers" timesyncd.enable timesyncd.servers)
        (check "services.timesyncd.fallbackServers" timesyncd.enable timesyncd.fallbackServers)
        (check "services.chrony.servers" chrony.enable chrony.servers)
        (check "services.ntp.servers" ntp.enable ntp.servers)
      ];
    };
}
