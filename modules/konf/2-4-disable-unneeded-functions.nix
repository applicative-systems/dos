# KONF.2.4 Deaktivierung nicht benötigter Systemfunktionen (normal-SdT, SOLLTE)
# Interpretation (server): disable what a server does not need and what the
# guidance names as attack surface: wireless/DMA interfaces (Bluetooth,
# FireWire), rarely used network protocols and filesystems (kernel modules
# cannot be loaded), discovery/printing services, and the default package set.
# Deviations are explicit: keepKernelModules / keepServices.
# Status "partial": the list is a starting point, not exhaustive.
import ../../lib/mkRequirement.nix {
  id = "KONF.2.4";

  options = lib: {
    keepKernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "sctp" ];
      description = "Kernel modules from the disabled list that this system needs.";
    };
    keepServices = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "bluetooth"
          "avahi"
          "printing"
        ]
      );
      default = [ ];
      description = "Services that this system needs although KONF.2.4 disables them by default.";
    };
  };

  apply =
    {
      config,
      lib,
      pkgs,
      cfg,
      ...
    }:
    let
      keepBluetooth = lib.elem "bluetooth" cfg.keepServices;

      disabledModules =
        lib.subtractLists
          (
            cfg.keepKernelModules
            ++ lib.optionals keepBluetooth [
              "bluetooth"
              "btusb"
            ]
          )
          [
            # wireless / DMA-capable interfaces
            "bluetooth"
            "btusb"
            "firewire-core"
            "firewire-ohci"
            "firewire-sbp2"
            # rarely used network protocols
            "dccp"
            "sctp"
            "rds"
            "tipc"
            "ax25"
            "netrom"
            "rose"
            # rarely used filesystems
            "cramfs"
            "freevxfs"
            "jffs2"
            "hfs"
            "hfsplus"
          ];

      serviceStates = {
        bluetooth = config.hardware.bluetooth.enable;
        avahi = config.services.avahi.enable;
        printing = config.services.printing.enable;
      };
    in
    {
      boot.blacklistedKernelModules = disabledModules;
      boot.extraModprobeConfig = lib.concatMapStringsSep "\n" (
        m: "install ${m} ${pkgs.coreutils}/bin/false"
      ) disabledModules;

      hardware.bluetooth.enable = lib.mkOverride 900 keepBluetooth;
      services.avahi.enable = lib.mkOverride 900 (lib.elem "avahi" cfg.keepServices);
      services.printing.enable = lib.mkOverride 900 (lib.elem "printing" cfg.keepServices);

      # Perl, rsync and strace are not needed on a hardened server.
      environment.defaultPackages = lib.mkOverride 900 [ ];

      assertions = lib.mapAttrsToList (name: enabled: {
        assertion = enabled -> lib.elem name cfg.keepServices;
        message = "KONF.2.4: the ${name} service is enabled but not listed in grundschutz.requirements.\"KONF.2.4\".keepServices.";
      }) serviceStates;
    };
}
