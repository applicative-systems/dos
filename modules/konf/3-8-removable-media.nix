# KONF.3.8 Einschränkung von Wechselmedien (normal-SdT, SOLLTE)
# Interpretation (status "partial"): no service may mount removable media
# automatically (udisks2, devmon, gvfs, autofs). Mounting by hand stays
# possible; the noexec alternative named in the text is not enforced for
# manual mounts. Desktops will need an opt-out later.
import ../../lib/mkRequirement.nix {
  id = "KONF.3.8";

  apply =
    { config, lib, ... }:
    let
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.3.8";
        items =
          map
            (svc: {
              path = [
                "services"
                svc
                "enable"
              ];
              value = false;
            })
            [
              "udisks2"
              "devmon"
              "gvfs"
              "autofs"
            ];
      };
    in
    lib.mkMerge [
      e.settings
      { inherit (e) assertions; }
    ];
}
