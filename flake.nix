{
  description = "NixOS modules implementing BSI Grundschutz++ requirements";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    mkdocs-flake = {
      url = "github:applicative-systems/mkdocs-flake";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        imports = [ inputs.mkdocs-flake.flakeModules.default ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        flake = {
          # One module per requirement, plus `default` importing all.
          nixosModules = import ./nix/requirement-modules.nix { inherit lib; } // {
            default = ./modules;
          };

          # Non-standard output: bundles enable sets of requirements.
          nixosProfiles = {
            konf-normal-sdt = ./profiles/konf-normal-sdt.nix;
          };
        };

        perSystem =
          {
            self',
            pkgs,
            system,
            ...
          }:
          {
            # docs, modules-markdown, status (documentation: see below)
            packages = import ./nix/packages.nix { inherit self lib pkgs; };

            # VM tests (tests/), assertion and evaluation checks, repository
            # checks (checks/); NixOS tests and evaluations need Linux.
            checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
              import ./checks {
                inherit
                  self
                  lib
                  pkgs
                  system
                  ;
              }
              # built with --strict: broken links fail
              // {
                inherit (self'.packages) documentation;
              }
            );

            # Website: `nix build .#documentation`; see nix/documentation.nix.
            documentation = import ./nix/documentation.nix { inherit self' pkgs; };

            devShells.default = pkgs.mkShell {
              packages = [
                pkgs.jq
                pkgs.reuse
                self'.formatter
              ];
            };

            formatter = import ./nix/treefmt.nix { inherit lib pkgs; };
          };
      }
    );
}
