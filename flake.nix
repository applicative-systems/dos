{
  description = "NixOS modules implementing BSI Grundschutz++ requirements";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      linuxPkgs = lib.filterAttrs (
        system: _: builtins.match ".*-linux" system != null
      ) inputs.nixpkgs.legacyPackages;
      # modules/<topic>/<n>-<m>-<slug>.nix -> nixosModules.<topic>-<n>-<m>
      requirementModules = lib.concatMapAttrs (
        topic: type:
        lib.optionalAttrs (type == "directory") (
          lib.concatMapAttrs (
            file: _:
            let
              m = builtins.match "([0-9]+-[0-9]+)-.*\\.nix" file;
            in
            lib.optionalAttrs (m != null) { "${topic}-${builtins.head m}" = ./modules + "/${topic}/${file}"; }
          ) (builtins.readDir (./modules + "/${topic}"))
        )
      ) (builtins.readDir ./modules);

      # One user setting per requirement that contradicts it.
      assertionCases = {
        "KONF.2.2".services.openssh = {
          enable = true;
          settings.Ciphers = [ "3des-cbc" ];
        };
        "KONF.2.4".hardware.bluetooth.enable = true;
        "KONF.4.3".services.openssh = {
          enable = true;
          settings.PasswordAuthentication = true;
        };
        "KONF.4.4".services.openssh = {
          enable = true;
          settings.PermitRootLogin = "yes";
        };
        "KONF.5.1".users.users.alice = {
          isNormalUser = true;
          hashedPassword = "";
        };
        "KONF.7.15".networking.firewall.enable = false;
        "KONF.7.16".boot.kernel.sysctl."kernel.kptr_restrict" = 0;
      };
    in
    {
      # One module per requirement, plus `default` importing all.
      nixosModules = requirementModules // {
        default = ./modules;
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
          formatting = inputs.self.formatter.${system}.check inputs.self;

          reuse = pkgs.runCommand "reuse-lint" { nativeBuildInputs = [ pkgs.reuse ]; } ''
            cd ${inputs.self}
            reuse lint
            touch $out
          '';

        }
        # Evaluation-only: at least one assertion of the requirement must fire
        # when the user contradicts it.
        // lib.mapAttrs' (
          id: contradiction:
          let
            eval = lib.nixosSystem {
              modules = [
                inputs.self.nixosModules.default
                contradiction
                {
                  grundschutz.requirements.${id}.enable = true;
                  system.stateVersion = "25.05";
                  nixpkgs.hostPlatform = system;
                }
              ];
            };
            failed = map (a: a.message) (
              builtins.filter (a: !a.assertion && lib.hasPrefix "${id}:" a.message) eval.config.assertions
            );
            name = "${lib.toLower (lib.replaceStrings [ "." ] [ "-" ] id)}-assertion";
          in
          lib.nameValuePair name (
            assert failed != [ ];
            pkgs.runCommand name { } "touch $out"
          )
        ) assertionCases
        # The whole profile must evaluate without any KONF assertion firing on
        # an ordinary configuration: requirements must not contradict each other.
        // {
          profile-konf-normal-sdt =
            let
              eval = lib.nixosSystem {
                modules = [
                  inputs.self.nixosProfiles.konf-normal-sdt
                  {
                    system.stateVersion = "25.05";
                    nixpkgs.hostPlatform = system;
                    services.openssh.enable = true;
                    users.users.alice = {
                      isNormalUser = true;
                      extraGroups = [ "wheel" ];
                      hashedPassword = "!";
                    };
                  }
                ];
              };
              failed = map (a: a.message) (
                builtins.filter (a: !a.assertion && lib.hasPrefix "KONF." a.message) eval.config.assertions
              );
            in
            assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
            pkgs.runCommand "profile-konf-normal-sdt" { } "touch $out";
        }
      ) linuxPkgs;

      devShells = builtins.mapAttrs (system: pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.jq
            pkgs.reuse
            inputs.self.formatter.${system}
          ];
        };
      }) inputs.nixpkgs.legacyPackages;

      formatter = builtins.mapAttrs (
        _system: pkgs:
        pkgs.treefmt.withConfig {
          settings = {
            tree-root-file = "flake.nix";
            on-unmatched = "info";
            formatter = {
              nixfmt = {
                command = lib.getExe pkgs.nixfmt;
                priority = 3; # last: lay out what the linters rewrote
                includes = [ "*.nix" ];
              };
              statix = {
                command = lib.getExe pkgs.statix;
                priority = 2;
                options = [ "fix" ];
                no-positional-arg-support = true;
                includes = [ "*.nix" ];
              };
              deadnix = {
                command = lib.getExe pkgs.deadnix;
                priority = 1;
                options = [ "--edit" ];
                includes = [ "*.nix" ];
              };
              shellcheck = {
                command = lib.getExe pkgs.shellcheck;
                includes = [ "*.sh" ];
              };
              shfmt = {
                command = lib.getExe pkgs.shfmt;
                options = [
                  "-w"
                  "-i"
                  "2"
                  "-s"
                ];
                includes = [ "*.sh" ];
              };
              taplo = {
                command = lib.getExe pkgs.taplo;
                options = [ "format" ];
                includes = [ "*.toml" ];
              };
              prettier = {
                command = lib.getExe pkgs.prettier;
                options = [ "--write" ];
                includes = [
                  "*.json"
                  "*.md"
                  "*.yaml"
                  "*.yml"
                ];
                # Unmodified BSI data (CC BY-SA), must stay byte-identical.
                excludes = [ "catalog/*" ];
              };
            };
          };
        }
      ) inputs.nixpkgs.legacyPackages;
    };
}
