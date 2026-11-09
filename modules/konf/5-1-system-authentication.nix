# KONF.5.1 Authentifizierung am System (normal-SdT, SOLLTE)
# Interpretation: every login, local or remote, must authenticate.
# Rejects accounts with an empty password, PAM services that accept empty
# passwords, and automatic console login. Remote specifics are in KONF.4.3.
import ../../lib/mkRequirement.nix {
  id = "KONF.5.1";
  apply =
    { config, lib, ... }:
    let
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.5.1";
        items = [
          {
            path = [
              "users"
              "allowNoPasswordLogin"
            ];
            value = false;
          }
          {
            path = [
              "services"
              "getty"
              "autologinUser"
            ];
            value = null;
          }
          # NixOS sets this to true as a plain default (programs/shadow.nix), so it
          # needs mkForce. Opt out of the whole requirement via `exempt`.
          {
            path = [
              "security"
              "pam"
              "services"
              "login"
              "allowNullPassword"
            ];
            value = false;
            priority = 50;
          }
        ];
      };
      emptyPassword = lib.attrNames (
        lib.filterAttrs (_: u: u.hashedPassword == "" || u.initialHashedPassword == "") config.users.users
      );
      nullPamServices = lib.attrNames (
        lib.filterAttrs (_: svc: svc.allowNullPassword) config.security.pam.services
      );
    in
    lib.mkMerge [
      e.settings
      {
        assertions = e.assertions ++ [
          {
            assertion = emptyPassword == [ ];
            message = "KONF.5.1: users with an empty password: ${lib.concatStringsSep ", " emptyPassword}.";
          }
          {
            assertion = nullPamServices == [ ];
            message = "KONF.5.1: PAM services accepting empty passwords: ${lib.concatStringsSep ", " nullPamServices}.";
          }
        ];
      }
    ];
}
