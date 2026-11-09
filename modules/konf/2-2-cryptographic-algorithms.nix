# KONF.2.2 Kryptographische Verfahren in IT-Systemen (normal-SdT, SOLLTE)
# The guidance defers to "current cryptographic methods" (BER.5.4/BER.7.x:
# "etablierte Algorithmen nach <anerkannten Standards>"). We take BSI
# TR-02102-4 (SSH, version 2026-01) as that standard.
#
# Interpretation, SSH only (status "partial": TLS etc. are not covered yet):
#  - KEX, ciphers, MACs, signature algorithms limited to Tables 2-5 of the TR,
#    mapped to OpenSSH names. diffie-hellman-group15-sha512 has no OpenSSH
#    equivalent. Encrypt-then-MAC variants of the listed HMACs and the
#    FIDO form of ecdsa-sha2-nistp256 are accepted as the same primitives.
#  - Ed25519/Curve25519 and RSA are NOT in the TR, so they are rejected.
#  - Host keys: ECDSA only. Rekey after 1 GB or 1 h (TR section 3.3.1).
# Applies to sshd (when enabled) and to the ssh client.
import ../../lib/mkRequirement.nix {
  id = "KONF.2.2";
  apply =
    { config, lib, ... }:
    let
      allowed = {
        kex = [
          "diffie-hellman-group-exchange-sha256"
          "diffie-hellman-group16-sha512"
          "ecdh-sha2-nistp256"
          "ecdh-sha2-nistp384"
          "ecdh-sha2-nistp521"
        ];
        ciphers = [
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "hmac-sha2-512"
          "hmac-sha2-256"
        ];
        hostKey = [
          "ecdsa-sha2-nistp256"
          "ecdsa-sha2-nistp384"
          "ecdsa-sha2-nistp521"
        ];
        pubkey = [
          "ecdsa-sha2-nistp256"
          "ecdsa-sha2-nistp384"
          "ecdsa-sha2-nistp521"
          "sk-ecdsa-sha2-nistp256@openssh.com"
        ];
      };

      subsetOf = list: actual: actual != null && lib.all (x: lib.elem x list) actual;
      listItem = path: list: {
        inherit path;
        value = list;
        ok = subsetOf list;
        expect = "a non-empty subset of ${builtins.toJSON list}";
      };

      # Freeform sshd settings only take scalars: comma-separated string.
      csvItem = path: list: {
        inherit path;
        value = lib.concatStringsSep "," list;
        ok = actual: actual != null && lib.all (x: lib.elem x list) (lib.splitString "," actual);
        expect = "a non-empty subset of ${builtins.toJSON list}";
      };

      server = [
        "services"
        "openssh"
        "settings"
      ];
      client = [
        "programs"
        "ssh"
      ];

      sshdItems = [
        (listItem (server ++ [ "KexAlgorithms" ]) allowed.kex)
        (listItem (server ++ [ "Ciphers" ]) allowed.ciphers)
        (listItem (server ++ [ "Macs" ]) allowed.macs)
        (csvItem (server ++ [ "HostKeyAlgorithms" ]) allowed.hostKey)
        (csvItem (server ++ [ "PubkeyAcceptedAlgorithms" ]) allowed.pubkey)
        {
          path = server ++ [ "RekeyLimit" ];
          value = "1G 1h";
        }
        {
          path = [
            "services"
            "openssh"
            "hostKeys"
          ];
          value = [
            {
              type = "ecdsa";
              bits = 384;
              path = "/etc/ssh/ssh_host_ecdsa_key";
            }
          ];
          ok = keys: lib.all (k: k.type == "ecdsa") keys;
          expect = "ECDSA keys only";
        }
      ];

      clientItems = [
        (listItem (client ++ [ "kexAlgorithms" ]) allowed.kex)
        (listItem (client ++ [ "ciphers" ]) allowed.ciphers)
        (listItem (client ++ [ "macs" ]) allowed.macs)
        (listItem (client ++ [ "hostKeyAlgorithms" ]) allowed.hostKey)
        (listItem (client ++ [ "pubkeyAcceptedKeyTypes" ]) allowed.pubkey)
      ];

      enforce =
        items:
        import ../../lib/enforce.nix {
          inherit lib config items;
          id = "KONF.2.2";
        };
      sshd = enforce sshdItems;
      ssh = enforce clientItems;
    in
    lib.mkMerge [
      ssh.settings
      { inherit (ssh) assertions; }
      sshd.settings
      # Conditioning the settings on services.openssh.enable would recurse.
      { assertions = lib.optionals config.services.openssh.enable sshd.assertions; }
    ];
}
