# One user setting per requirement that contradicts it; see ./assertions.nix.
# Keys are requirement IDs, optionally with a "/<variant>" suffix for further
# cases of the same requirement. Every requirement needs at least one case
# (enforced by the consistency check).
{ lib }:
{
  "KONF.2.2".services.openssh = {
    enable = true;
    settings.Ciphers = [ "3des-cbc" ];
  };
  "KONF.2.3".users.users.alice = {
    isNormalUser = true;
    initialPassword = "changeme";
  };
  "KONF.2.4".hardware.bluetooth.enable = true;
  "KONF.2.5".system.configurationRevision = null;
  "KONF.2.5/dirty".system.configurationRevision = "0123abc-dirty";
  "KONF.3.1".security.tpm2.enable = false;
  # no LUKS device, no other encryption declared
  "KONF.3.2" = { };
  "KONF.3.8".services.udisks2.enable = true;
  # desktop mode, but users may request exec on removable media
  "KONF.3.8/noexec" = {
    grundschutz.requirements."KONF.3.8".automount = "noexec";
    services.udisks2 = {
      enable = true;
      settings."mount_options.conf".defaults.allow = "exec,noexec";
    };
  };
  "KONF.4.3".services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  "KONF.4.4".services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  # root login off, wheel has no members: nobody could log in
  "KONF.4.4/lockout".services.openssh.enable = true;
  # only an Ed25519 key while KONF.2.2 limits keys to ECDSA
  "KONF.4.4/ed25519-only" = {
    services.openssh.enable = true;
    grundschutz.requirements."KONF.2.2".enable = true;
    users.users.alice = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholder alice@example" ];
    };
  };
  # no allowlist given
  "KONF.4.5" = { };
  "KONF.4.5/chrony" = {
    grundschutz.requirements."KONF.4.5".allowedTimeServers = [ "ntp.example.org" ];
    services.chrony = {
      enable = true;
      servers = [ "pool.ntp.org" ];
    };
  };
  "KONF.5.1".users.users.alice = {
    isNormalUser = true;
    hashedPassword = "";
  };
  "KONF.6.4".security.sudo.execWheelOnly = false;
  "KONF.7.9".nix.settings.allowed-users = [ "*" ];
  "KONF.7.10".boot.specialFileSystems."/dev/shm".options = lib.mkForce [ "nosuid" ];
  "KONF.7.15".networking.firewall.enable = false;
  "KONF.7.16".boot.kernel.sysctl."kernel.kptr_restrict" = 0;
  "KONF.8.1".system.autoUpgrade.enable = false;
  # builds the update but never activates it
  "KONF.8.2".system.autoUpgrade = {
    enable = true;
    operation = "boot";
  };
}
