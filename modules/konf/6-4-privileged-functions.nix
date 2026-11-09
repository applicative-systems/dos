# KONF.6.4 Privilegierte Systemfunktionen (normal-SdT, SOLLTE)
# Interpretation (status "partial"): privilege escalation is restricted to
# members of group wheel and requires a password.
#   privilegeEscalation = "sudo" (default): sudo executable only for wheel,
#     sudo asks for a password, su requires wheel.
#   privilegeEscalation = "run0": systemd's run0 via polkit; no setuid sudo
#     (sudo and sudo-rs are disabled), run0 asks wheel members for a password.
# Role-based administration (KANN) and the setuid wrapper inventory are not
# enforced. With root login disabled (KONF.4.4) and key-only SSH (KONF.4.3),
# admin users need a password hash; set `allowPasswordlessSudo` (which only
# lifts the requirement, set the sudo/run0 option yourself) for deployment
# setups that rely on NOPASSWD.
import ../../lib/mkRequirement.nix {
  id = "KONF.6.4";

  options = lib: {
    privilegeEscalation = lib.mkOption {
      type = lib.types.enum [
        "sudo"
        "run0"
      ];
      default = "sudo";
      description = ''
        Which tool provides privilege escalation.

        `sudo`: mature, supports per-command rules (sudoers, useful for
        role-based administration) and is what deploy tools expect, but it is
        a setuid binary, so its bugs are local privilege escalations.

        `run0`: systemd starts the command, polkit authorizes it, so there is
        no setuid binary. In exchange it needs the polkit daemon, has no
        sudoers-style per-command rules, is newer, and tools that call `sudo`
        only work through the `security.run0.sudo-shim` (not all flags).
      '';
    };
    allowPasswordlessSudo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Do not require (or assert) a password for sudo/run0 by members of wheel; set security.sudo.wheelNeedsPassword or security.run0.wheelNeedsPassword to false yourself.";
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
      sudo = cfg.privilegeEscalation == "sudo";
      run0 = cfg.privilegeEscalation == "run0";
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.6.4";
        items = [
          {
            path = [
              "security"
              "pam"
              "services"
              "su"
              "requireWheel"
            ];
            value = true;
          }
          {
            path = [
              "security"
              "sudo"
              "execWheelOnly"
            ];
            value = true;
            when = sudo;
          }
          {
            path = [
              "security"
              "sudo"
              "wheelNeedsPassword"
            ];
            value = true;
            when = sudo && !cfg.allowPasswordlessSudo;
          }
          {
            path = [
              "security"
              "sudo"
              "enable"
            ];
            value = false;
            when = run0;
          }
          {
            path = [
              "security"
              "sudo-rs"
              "enable"
            ];
            value = false;
            when = run0;
          }
          {
            path = [
              "security"
              "run0"
              "enable"
            ];
            value = true;
            when = run0;
          }
          {
            path = [
              "security"
              "run0"
              "wheelNeedsPassword"
            ];
            value = true;
            when = run0 && !cfg.allowPasswordlessSudo;
          }
        ];
      };
    in
    lib.mkMerge [
      e.settings
      { inherit (e) assertions; }
    ];
}
