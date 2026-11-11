# KONF.3.2 Speicherverschlüsselung (normal-SdT, SOLLTE)
# Interpretation: persistent storage is encrypted with dm-crypt/LUKS, i.e. at
# least one boot.initrd.luks.devices entry exists (fileSystems.<n>.encrypted
# and disko's LUKS layouts create such entries). Encryption that the NixOS
# configuration cannot show, such as ZFS native encryption, bcachefs
# encryption or self-encrypting drives, is declared in `otherEncryption`.
# Unencrypted storage (e.g. a cloud provider's volumes) needs an exemption.
# Status "partial": it is not verified that every persistent filesystem sits
# on an encrypted device, nor which cipher LUKS uses (see BSI TR-02102-1).
import ../../lib/mkRequirement.nix {
  id = "KONF.3.2";

  options = lib: {
    otherEncryption = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching ".+");
      default = null;
      example = "ZFS native encryption (aes-256-gcm) on all datasets of rpool";
      description = ''
        Description of storage encryption that is not configured through
        boot.initrd.luks.devices. Setting it satisfies the requirement.
      '';
    };
  };

  apply =
    {
      config,
      cfg,
      ...
    }:
    {
      assertions = [
        {
          assertion = config.boot.initrd.luks.devices != { } || cfg.otherEncryption != null;
          message = "KONF.3.2: no storage encryption configured: boot.initrd.luks.devices is empty. Encrypt with LUKS, describe other encryption in grundschutz.requirements.\"KONF.3.2\".otherEncryption, or set the requirement exempt.";
        }
      ];
    };
}
