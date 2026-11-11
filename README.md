# Deutschland-OS

NixOS modules that implement our interpretation of BSI **Grundschutz++** requirements.
This is not an official BSI product and does not make a system "BSI-compliant".

## Background

- [IT-Grundschutz](https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/it-grundschutz_node.html) – the BSI's information security methodology; **Grundschutz++** is its machine-readable successor.
- [Stand-der-Technik-Bibliothek](https://github.com/BSI-Bund/Stand-der-Technik-Bibliothek) – the BSI's GitHub repository with the Grundschutz++ catalog (OSCAL/JSON) that `catalog/` copies. Requirement IDs such as `KONF.7.10` refer to it; `normal-SdT` and `erhöht` are its security levels.
- [BSI TR-02102](https://www.bsi.bund.de/dok/TR-02102-en) – technical guidelines on cryptographic mechanisms; [TR-02102-4](https://www.bsi.bund.de/SharedDocs/Downloads/EN/BSI/Publications/TechGuidelines/TG02102/BSI-TR-02102-4.html) covers SSH and is the basis of the SSH algorithm requirements (KONF.2.2, 4.3, 4.4).

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
- `docs/STATUS.md` – generated status of all 652 catalog controls (`tools/update-status.sh`; `nix flake check` fails if it is stale)
- `nix build .#docs` – Markdown page per implemented requirement: our interpretation, options, tests and the original BSI statement and guidance (CC BY-SA 4.0)
- `nix build .#modules-markdown` – NixOS option reference of all modules (`nixosOptionsDoc`)
- `tools/coverage.sh` – catalog controls vs. mapping

Code is MIT; `catalog/` is CC BY-SA 4.0 (REUSE.toml). Don't paste BSI requirement text into `.nix` files, reference IDs only.
