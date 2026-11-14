# Evaluation-only checks of whole configurations.
{
  self,
  lib,
  pkgs,
  system,
  helpers,
  ...
}:
{
  # pti= is x86-only: the unknown parameter must not show up on aarch64.
  konf-7-16-no-pti-on-aarch64 =
    let
      eval = helpers.evalSystem "aarch64-linux" [
        self.nixosModules.default
        { grundschutz.requirements."KONF.7.16".enable = true; }
      ];
      failed = helpers.failedAssertions "KONF." eval;
    in
    assert lib.assertMsg (!(builtins.elem "pti=on" eval.config.boot.kernelParams)) "pti=on on aarch64";
    assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
    pkgs.runCommand "konf-7-16-no-pti-on-aarch64" { } "touch $out";

  # Plasma's screen locker must not accept empty passwords (KONF.5.1).
  konf-5-1-plasma =
    let
      eval = helpers.evalSystem system [
        self.nixosModules.default
        {
          grundschutz.requirements."KONF.5.1".enable = true;
          services.desktopManager.plasma6.enable = true;
        }
      ];
      failed = helpers.failedAssertions "KONF." eval;
    in
    assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
    assert lib.assertMsg (
      !eval.config.security.pam.services.kde.allowNullPassword
    ) "kde accepts empty passwords";
    pkgs.runCommand "konf-5-1-plasma" { } "touch $out";

  # With KONF.2.2 exempted, the KONF.4.4 lockout guard accepts any key type.
  konf-4-4-ed25519-with-2-2-exempt =
    let
      eval = helpers.evalSystem system [
        self.nixosModules.default
        {
          grundschutz.requirements = {
            "KONF.2.2" = {
              enable = true;
              exempt = "test";
            };
            "KONF.4.4".enable = true;
          };
          services.openssh.enable = true;
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder alice@example" ];
          };
        }
      ];
      failed = helpers.failedAssertions "KONF." eval;
    in
    assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
    pkgs.runCommand "konf-4-4-ed25519-with-2-2-exempt" { } "touch $out";

  # The whole profile must evaluate without any KONF assertion firing on an
  # ordinary configuration: requirements must not contradict each other.
  profile-konf-normal-sdt =
    let
      eval = helpers.evalSystem system [
        self.nixosProfiles.konf-normal-sdt
        {
          services.openssh.enable = true;
          system.configurationRevision = "0123456789abcdef0123456789abcdef01234567";
          system.autoUpgrade = {
            enable = true;
            flake = "github:example/infra";
          };
          grundschutz.requirements."KONF.4.5".allowedTimeServers = [ "ntp.example.org" ];
          boot.initrd.luks.devices.cryptroot.device = "/dev/disk/by-partlabel/cryptroot";
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            hashedPassword = "!";
            # ECDSA, as KONF.2.2 requires (dummy key, only its type matters)
            openssh.authorizedKeys.keys = [
              "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPlaceholder alice@example"
            ];
          };
        }
      ];
      failed = helpers.failedAssertions "KONF." eval;
    in
    assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
    pkgs.runCommand "profile-konf-normal-sdt" { } "touch $out";

  # The desktop profile must accept what a GNOME desktop with fwupd brings
  # (udisks2, gvfs) and still hand out removable media noexec only.
  profile-konf-normal-sdt-desktop =
    let
      eval = helpers.evalSystem system [
        self.nixosProfiles.konf-normal-sdt-desktop
        {
          services.desktopManager.gnome.enable = true;
          services.displayManager.gdm.enable = true;
          services.fwupd.enable = true;
          system.configurationRevision = "0123456789abcdef0123456789abcdef01234567";
          system.autoUpgrade = {
            enable = true;
            flake = "github:example/infra";
            operation = "switch";
          };
          grundschutz.requirements."KONF.2.4".keepServices = [
            "avahi"
            "printing"
            "bluetooth"
          ];
          grundschutz.requirements."KONF.4.5".allowedTimeServers = [ "ntp.example.org" ];
          boot.initrd.luks.devices.cryptroot.device = "/dev/disk/by-partlabel/cryptroot";
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            hashedPassword = "!";
          };
        }
      ];
      failed = helpers.failedAssertions "KONF." eval;
      udisks = eval.config.services.udisks2;
    in
    assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
    assert lib.assertMsg udisks.enable "udisks2 disabled";
    assert lib.assertMsg (
      udisks.settings."mount_options.conf".defaults.defaults == "noexec"
    ) "udisks2 mounts are not noexec";
    pkgs.runCommand "profile-konf-normal-sdt-desktop" { } "touch $out";
}
