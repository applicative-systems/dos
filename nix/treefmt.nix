{ lib, pkgs }:
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
