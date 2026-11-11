{
  description = "NixOS modules implementing BSI Grundschutz++ requirements";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      inherit (inputs) self;
      inherit (inputs.nixpkgs) lib;
      allSystems = inputs.nixpkgs.legacyPackages;
      # NixOS tests and evaluations need Linux.
      linuxSystems = lib.filterAttrs (system: _: lib.hasSuffix "-linux" system) allSystems;
    in
    {
      # One module per requirement, plus `default` importing all.
      nixosModules = import ./nix/requirement-modules.nix { inherit lib; } // {
        default = ./modules;
      };

      # Non-standard output: bundles enable sets of requirements.
      nixosProfiles = {
        konf-normal-sdt = ./profiles/konf-normal-sdt.nix;
      };

      # VM tests (tests/), assertion and evaluation checks, repository checks (checks/)
      checks = builtins.mapAttrs (
        system: pkgs:
        import ./checks {
          inherit
            self
            lib
            pkgs
            system
            ;
        }
      ) linuxSystems;

      # docs, modules-markdown, status
      packages = builtins.mapAttrs (
        _system: pkgs: import ./nix/packages.nix { inherit self lib pkgs; }
      ) allSystems;

      devShells = builtins.mapAttrs (system: pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.jq
            pkgs.reuse
            self.formatter.${system}
          ];
        };
      }) allSystems;

      formatter = builtins.mapAttrs (
        _system: pkgs: import ./nix/treefmt.nix { inherit lib pkgs; }
      ) allSystems;
    };
}
