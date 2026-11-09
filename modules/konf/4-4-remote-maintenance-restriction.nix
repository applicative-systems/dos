# KONF.4.4 Einschränkung von Fernwartungsfunktionen (normal-SdT, SOLLTE)
# Interpretation, SSH only (status "partial"): no root login, only members of
# `allowGroups` may log in, and tunnelling/forwarding is off unless
# `allowForwarding` is set. Deploy tools should use a normal admin user
# with sudo instead of root.
import ../../lib/mkRequirement.nix {
  id = "KONF.4.4";

  options = lib: {
    allowGroups = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      default = [ "wheel" ];
      description = "Groups whose members may log in via SSH.";
    };
    allowForwarding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Permit TCP/agent/X11 forwarding and tunnels. Disabled by default.";
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
      s = name: [
        "services"
        "openssh"
        "settings"
        name
      ];
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.4.4";
        items = [
          {
            path = s "PermitRootLogin";
            value = "no";
          }
          {
            path = s "AllowGroups";
            value = cfg.allowGroups;
          }
        ]
        ++ map (i: i // { when = !cfg.allowForwarding; }) [
          {
            path = s "AllowTcpForwarding";
            value = false;
          }
          {
            path = s "AllowAgentForwarding";
            value = false;
          }
          {
            path = s "X11Forwarding";
            value = false;
          }
          {
            path = s "GatewayPorts";
            value = "no";
          }
          {
            path = s "PermitTunnel";
            value = false;
          }
        ];
      };
    in
    lib.mkMerge [
      e.settings
      # Conditioning the settings on services.openssh.enable would recurse.
      { assertions = lib.optionals config.services.openssh.enable e.assertions; }
    ];
}
