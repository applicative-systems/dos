# grundschutz-nixos

NixOS modules that implement our interpretation of BSI **Grundschutz++** requirements.
This is not an official BSI product and does not make a system "BSI-compliant".

```nix
# flake.nix of your system
modules = [ grundschutz.nixosProfiles.konf-normal-sdt ];

# deviate explicitly and visibly:
grundschutz.requirements."KONF.7.15".exempt = "Firewalling done upstream, see R-42";
```

- `catalog/` – unmodified BSI OSCAL data (CC BY-SA 4.0, see `catalog/NOTICE.md`)
- `mapping/mapping.json` – per requirement: status (`implemented|partial|manual|not-applicable`), modules, tests, rationale
- `modules/<topic>/` – (flake output `nixosModules.<id>`) one module per requirement; enforce settings and/or assert on user config
- `profiles/` – (flake output `nixosProfiles`) bundles per security level (`normal-SdT`, `erhöht`)
- `tests/` – NixOS VM tests that check runtime state
- `tools/coverage.sh` – catalog controls vs. mapping

Code is MIT; `catalog/` is CC BY-SA 4.0 (REUSE.toml). Don't paste BSI requirement text into `.nix` files, reference IDs only.
