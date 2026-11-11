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
}
