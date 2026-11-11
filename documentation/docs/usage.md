# Usage

Add the flake as an input and import a profile, or single requirement modules.

```nix
{
  inputs.grundschutz.url = "github:applicative-systems/dos";

  outputs = { nixpkgs, grundschutz, ... }: {
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      modules = [
        grundschutz.nixosProfiles.konf-normal-sdt
        ./configuration.nix
      ];
    };
  };
}
```

## Profiles

`nixosProfiles.konf-normal-sdt` enables every implemented KONF requirement of level `normal-SdT`.
Some requirements need input that only you can provide, or they fail evaluation:

- KONF.2.5: `system.configurationRevision`, e.g. `self.rev or self.dirtyRev or null`
- KONF.3.2: LUKS-encrypted storage (`boot.initrd.luks.devices`), or a description of other encryption such as ZFS native encryption in `grundschutz.requirements."KONF.3.2".otherEncryption`
- KONF.4.5: `grundschutz.requirements."KONF.4.5".allowedTimeServers`
- KONF.8.1 and KONF.8.2: `system.autoUpgrade.enable`, or an exemption if updates are rolled out centrally (CI, colmena, deploy-rs)

KONF.3.1 enables the TPM2 stack; on hardware without TPM, exempt it.

## Single requirements

`nixosModules.default` declares all requirements without enabling any.
Enable them one by one:

```nix
{
  imports = [ grundschutz.nixosModules.default ];
  grundschutz.requirements."KONF.7.15".enable = true;
}
```

## Deviations

Every requirement has an `exempt` option.
It takes the reason for the deviation, disables the requirement's enforcement and emits a warning on every build, so the deviation stays visible:

```nix
grundschutz.requirements."KONF.7.15".exempt = "Firewalling done upstream, see R-42";
```

## Failed assertions

When the configuration contradicts a requirement, evaluation fails with a message that starts with the requirement ID, e.g. `KONF.4.5: ...`.
The [requirement page](requirements/index.md) of that ID explains what we enforce and quotes the original BSI text.
