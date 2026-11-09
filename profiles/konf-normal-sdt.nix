# Enables all implemented KONF requirements of level "normal-SdT".
# Note: the SSH requirements follow BSI TR-02102-4, which does not list
# Ed25519 or RSA; with sshd enabled, users need ECDSA keys (see KONF.2.2).
{ lib, ... }:
{
  imports = [ ../modules ];
  grundschutz.requirements = {
    "KONF.2.2".enable = lib.mkDefault true;
    "KONF.2.3".enable = lib.mkDefault true;
    "KONF.2.4".enable = lib.mkDefault true;
    "KONF.4.3".enable = lib.mkDefault true;
    "KONF.4.4".enable = lib.mkDefault true;
    "KONF.5.1".enable = lib.mkDefault true;
    "KONF.7.15".enable = lib.mkDefault true;
    "KONF.7.16".enable = lib.mkDefault true;
  };
}
