# KONF.2.3 Default-Zugangsdaten in IT-Systemen (normal-SdT, SOLLTE)
# Interpretation: no plaintext passwords in the configuration, since those
# end up world-readable in the Nix store and are de facto shared defaults.
# Hashed/file-based secrets are fine. Status "partial": we cannot detect
# well-known hashes.
import ../../lib/mkRequirement.nix {
  id = "KONF.2.3";
  apply = { config, lib, ... }:
    let
      offenders = lib.attrNames (lib.filterAttrs
        (_: u: u.password != null || u.initialPassword != null)
        config.users.users);
    in {
      assertions = [{
        assertion = offenders == [ ];
        message = "KONF.2.3: plaintext password/initialPassword set for users: ${lib.concatStringsSep ", " offenders}. Use hashedPasswordFile or similar.";
      }];
    };
}
