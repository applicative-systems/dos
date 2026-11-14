# KONF.3.8 Einschränkung von Wechselmedien (normal-SdT, SOLLTE)
# Interpretation (status "partial"), two modes:
#   automount = "off" (default, servers): no service may mount removable media
#     automatically (udisks2, devmon, gvfs, autofs). Mounting by hand stays
#     possible and is not forced to noexec.
#   automount = "noexec" (desktops): udisks2 (and gvfs on top of it) may mount
#     removable media, but only noexec. udisks itself always adds nodev,nosuid;
#     /etc/udisks2/mount_options.conf adds noexec to the defaults of every
#     filesystem and drops exec/suid/dev from the options users may request.
#     devmon and autofs stay off. Manual mounts by root are not covered.
import ../../lib/mkRequirement.nix {
  id = "KONF.3.8";

  options = lib: {
    automount = lib.mkOption {
      type = lib.types.enum [
        "off"
        "noexec"
      ];
      default = "off";
      description = ''
        `off`: no automounter at all. `noexec`: udisks2/gvfs may mount
        removable media for desktop users, always with noexec,nosuid,nodev.
      '';
    };
  };

  apply =
    {
      config,
      lib,
      cfg,
      ...
    }:
    let
      noexec = cfg.automount == "noexec";

      # udisks' built-in [defaults] allow list without exec, suid and dev
      # (data/builtin_mount_options.conf in udisks); filesystem-specific
      # allow lists do not contain any of them.
      allow = lib.concatStringsSep "," [
        "noexec"
        "nodev"
        "nosuid"
        "atime"
        "noatime"
        "nodiratime"
        "relatime"
        "strictatime"
        "lazytime"
        "ro"
        "rw"
        "sync"
        "dirsync"
        "noload"
        "acl"
        "nosymfollow"
      ];
      udisksOption =
        key: item:
        item
        // {
          path = [
            "services"
            "udisks2"
            "settings"
            "mount_options.conf"
            "defaults"
            key
          ];
          when = noexec;
        };

      off = svc: when: {
        path = [
          "services"
          svc
          "enable"
        ];
        value = false;
        inherit when;
      };

      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.3.8";
        items = [
          (off "udisks2" (!noexec))
          (off "gvfs" (!noexec))
          (off "devmon" true)
          (off "autofs" true)
          (udisksOption "defaults" {
            value = "noexec";
            ok = a: a != null && lib.elem "noexec" (lib.splitString "," a);
            expect = "a list of options containing noexec";
          })
          (udisksOption "allow" {
            value = allow;
            ok =
              a:
              a != null
              && !lib.any (o: lib.elem o (lib.splitString "," a)) [
                "exec"
                "suid"
                "dev"
              ];
            expect = "a list of options without exec, suid and dev";
          })
        ];
      };
    in
    lib.mkMerge [
      e.settings
      { inherit (e) assertions; }
    ];
}
