{
  description = "NixOS modules implementing BSI Grundschutz++ requirements";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      # VM tests need Linux; keep darwin etc. out of `checks`.
      linuxPkgs = lib.filterAttrs (
        system: _: builtins.match ".*-linux" system != null
      ) inputs.nixpkgs.legacyPackages;
    in
    {
      # One module per requirement, plus `default` importing all.
      nixosModules = {
        default = ./modules;
        konf-7-15 = ./modules/konf/7-15-local-firewall.nix;
        konf-2-3 = ./modules/konf/2-3-default-credentials.nix;
      };

      # Non-standard output: bundles enable sets of requirements.
      nixosProfiles = {
        konf-normal-sdt = ./profiles/konf-normal-sdt.nix;
      };

      checks = builtins.mapAttrs (
        system: pkgs:
        # Every ./tests/<name>.nix is a runNixOSTest module; the grundschutz
        # modules are injected here so tests do not need to know their origin.
        (lib.mapAttrs' (file: _: {
          name = lib.removeSuffix ".nix" file;
          value = pkgs.testers.runNixOSTest {
            imports = [ (./tests + "/${file}") ];
            extraBaseModules.imports = [ ./modules ];
          };
        }) (builtins.readDir ./tests))
        // {

          # Evaluation-only: the assertion must fire when the user contradicts it.
          konf-7-15-assertion =
            let
              eval = lib.nixosSystem {
                modules = [
                  inputs.self.nixosModules.default
                  {
                    grundschutz.requirements."KONF.7.15".enable = true;
                    networking.firewall.enable = false;
                    system.stateVersion = "25.05";
                    nixpkgs.hostPlatform = system;
                  }
                ];
              };
              failed = map (a: a.message) (
                builtins.filter (a: !a.assertion && lib.hasPrefix "KONF." a.message) eval.config.assertions
              );
            in
            assert builtins.length failed == 1;
            pkgs.runCommand "konf-7-15-assertion" { } "touch $out";
        }
      ) linuxPkgs;

      devShells = builtins.mapAttrs (system: pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.jq
            pkgs.reuse
          ];
        };
      }) inputs.nixpkgs.legacyPackages;
    };
}
