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
        "KONF.3.8".services.udisks2.enable = true;
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
        "KONF.5.1".users.users.alice = {
          isNormalUser = true;
          hashedPassword = "";
        };
        "KONF.6.4".security.sudo.execWheelOnly = false;
        "KONF.7.10".boot.specialFileSystems."/dev/shm".options = lib.mkForce [ "nosuid" ];
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

          status-up-to-date = pkgs.runCommand "status-up-to-date" { } ''
            diff ${./docs/STATUS.md} ${inputs.self.packages.${system}.status} \
              || { echo "docs/STATUS.md is stale: run tools/update-status.sh"; exit 1; }
            touch $out
          '';

          mapping-paths = pkgs.runCommand "mapping-paths" { nativeBuildInputs = [ pkgs.jq ]; } ''
            cd ${inputs.self}
            missing=$(jq -r '.[] | ((.modules // []) + (.tests // []))[]' mapping/mapping.json \
              | while read -r p; do [ -e "$p" ] || echo "$p"; done)
            [ -z "$missing" ] || { echo "mapping.json references missing files:"; echo "$missing"; exit 1; }
            touch $out
          '';

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
            reqId = builtins.head (lib.splitString "/" id);
            eval = lib.nixosSystem {
              modules = [
                inputs.self.nixosModules.default
                contradiction
                {
                  grundschutz.requirements.${reqId}.enable = true;
                  system.stateVersion = "25.05";
                  nixpkgs.hostPlatform = system;
                }
              ];
            };
            failed = map (a: a.message) (
              builtins.filter (a: !a.assertion && lib.hasPrefix "${reqId}:" a.message) eval.config.assertions
            );
            name = "${lib.toLower (lib.replaceStrings [ "." "/" ] [ "-" "-" ] id)}-assertion";
          in
          lib.nameValuePair name (
            assert failed != [ ];
            pkgs.runCommand name { } "touch $out"
          )
        ) assertionCases
        # pti= is x86-only: the unknown parameter must not show up on aarch64.
        // {
          konf-7-16-no-pti-on-aarch64 =
            let
              eval = lib.nixosSystem {
                modules = [
                  inputs.self.nixosModules.default
                  {
                    grundschutz.requirements."KONF.7.16".enable = true;
                    system.stateVersion = "25.05";
                    nixpkgs.hostPlatform = "aarch64-linux";
                  }
                ];
              };
              params = eval.config.boot.kernelParams;
              failed = map (a: a.message) (
                builtins.filter (a: !a.assertion && lib.hasPrefix "KONF." a.message) eval.config.assertions
              );
            in
            assert lib.assertMsg (!(builtins.elem "pti=on" params)) "pti=on on aarch64";
            assert lib.assertMsg (failed == [ ]) (lib.concatStringsSep "\n" failed);
            pkgs.runCommand "konf-7-16-no-pti-on-aarch64" { } "touch $out";
        }
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
                      # ECDSA, as KONF.2.2 requires (dummy key, only its type matters)
                      openssh.authorizedKeys.keys = [
                        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPlaceholder alice@example"
                      ];
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

      packages = builtins.mapAttrs (_system: pkgs: {
        # docs/STATUS.md: every catalog control joined with the mapping
        status =
          pkgs.runCommand "STATUS.md" { nativeBuildInputs = [ pkgs.jq ]; }
            "jq -r --slurpfile m ${./mapping/mapping.json} -f ${./tools/status.jq} ${./catalog/Grundschutz++-resolved_catalog.json} > $out";
      }) inputs.nixpkgs.legacyPackages;

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
                excludes = [
                  "catalog/*"
                  "docs/STATUS.md" # generated
                ];
              };
            };
          };
        }
      ) inputs.nixpkgs.legacyPackages;
    };
}
