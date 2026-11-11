# Enables all implemented KONF requirements of level "normal-SdT".
# Note: the SSH requirements follow BSI TR-02102-4, which does not list
# Ed25519 or RSA; with sshd enabled, users need ECDSA keys (see KONF.2.2).
# KONF.6.4 makes sudo ask for a password, so admin users need a password hash
# (root login is off, SSH is key-only). KONF.7.10 mounts /tmp noexec: Nix builds
# using /tmp need `keepExec = [ "/tmp" ]`.
# Settings every user of this profile has to provide (or exempt):
# - KONF.2.5: system.configurationRevision (e.g. `self.rev or self.dirtyRev or null`)
# - KONF.4.5: grundschutz.requirements."KONF.4.5".allowedTimeServers
# - KONF.8.1/8.2: system.autoUpgrade.enable; exempt both if updates are pushed
#   centrally (CI, colmena, deploy-rs)
# KONF.7.9 limits the Nix daemon to root and wheel.
{ lib, ... }:
{
  imports = [ ../modules ];
  grundschutz.requirements = {
    "KONF.2.2".enable = lib.mkDefault true;
    "KONF.2.3".enable = lib.mkDefault true;
    "KONF.2.4".enable = lib.mkDefault true;
    "KONF.2.5".enable = lib.mkDefault true;
    "KONF.3.8".enable = lib.mkDefault true;
    "KONF.4.3".enable = lib.mkDefault true;
    "KONF.4.4".enable = lib.mkDefault true;
    "KONF.4.5".enable = lib.mkDefault true;
    "KONF.5.1".enable = lib.mkDefault true;
    "KONF.6.4".enable = lib.mkDefault true;
    "KONF.7.9".enable = lib.mkDefault true;
    "KONF.7.10".enable = lib.mkDefault true;
    "KONF.7.15".enable = lib.mkDefault true;
    "KONF.7.16".enable = lib.mkDefault true;
    "KONF.8.1".enable = lib.mkDefault true;
    "KONF.8.2".enable = lib.mkDefault true;
  };
}
