# KONF.4.4 Einschränkung von Fernwartungsfunktionen (normal-SdT, SOLLTE)
# Interpretation, SSH only (status "partial"): no root login, only members of
# `allowGroups` may log in, and tunnelling/forwarding is off unless
# `allowForwarding` is set. Deploy tools should use a normal admin user
# with sudo instead of root.
# Lockout guard: with sshd on, some user in `allowGroups` must have an authorized
# key (of an ECDSA type when KONF.2.2 is enabled), else evaluation fails.
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
      # Lockout guard: with root login off and AllowGroups set, someone must
      # still be able to log in. KONF.2.2 limits public keys to ECDSA, so keys
      # of other types do not count when it is enabled.
      strictKeys = config.grundschutz.requirements."KONF.2.2".enable;
      acceptedKey =
        k:
        !strictKeys
        ||
          builtins.match ".*(ecdsa-sha2-nistp(256|384|521)|sk-ecdsa-sha2-nistp256@openssh\\.com) .*" k
          != null;
      inGroup = u: lib.any (g: u.group == g || lib.elem g u.extraGroups) cfg.allowGroups;
      listedMember =
        u: lib.any (g: lib.elem u.name (config.users.groups.${g}.members or [ ])) cfg.allowGroups;
      canLogin =
        u:
        u.name != "root"
        && (inGroup u || listedMember u)
        # keyFiles cannot be read at evaluation time; trust them.
        && (u.openssh.authorizedKeys.keyFiles != [ ] || lib.any acceptedKey u.openssh.authorizedKeys.keys);
      lockout = {
        assertion = lib.any canLogin (lib.attrValues config.users.users);
        message =
          "KONF.4.4: SSH login would be impossible: root login is disabled and no user in "
          + "AllowGroups (${lib.concatStringsSep ", " cfg.allowGroups}) has an authorized key"
          + lib.optionalString strictKeys " of an accepted type (ECDSA, see KONF.2.2)"
          + ". Add such a user (users.users.<name>.openssh.authorizedKeys.keys) or set the requirement exempt.";
      };
    in
    lib.mkMerge [
      e.settings
      # Conditioning the settings on services.openssh.enable would recurse.
      { assertions = lib.optionals config.services.openssh.enable (e.assertions ++ [ lockout ]); }
    ];
}
