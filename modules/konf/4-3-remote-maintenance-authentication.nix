# KONF.4.3 Authentifizierung von Fernwartungsfunktionen (normal-SdT, SOLLTE)
# Interpretation, SSH only (status "partial": RDP, SNMP etc. not covered):
# sshd accepts public key authentication only. Passwords, keyboard-interactive
# and host-based authentication are off. Which key types are acceptable is
# decided by KONF.2.2 (BSI TR-02102-4 recommends public key authentication).
import ../../lib/mkRequirement.nix {
  id = "KONF.4.3";
  apply =
    { config, lib, ... }:
    let
      s = name: [
        "services"
        "openssh"
        "settings"
        name
      ];
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.4.3";
        items = [
          {
            path = s "PubkeyAuthentication";
            value = true;
          }
          {
            path = s "PasswordAuthentication";
            value = false;
          }
          {
            path = s "KbdInteractiveAuthentication";
            value = false;
          }
          {
            path = s "PermitEmptyPasswords";
            value = false;
          }
          {
            path = s "HostbasedAuthentication";
            value = false;
          }
          {
            path = s "AuthenticationMethods";
            value = "publickey";
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
