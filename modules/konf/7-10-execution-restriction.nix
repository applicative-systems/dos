# KONF.7.10 Einschränkung der Ausführung (normal-SdT, SOLLTE)
# Interpretation (status "partial"): world-writable data locations must not
# allow program execution. /tmp, /var/tmp and /dev/shm get noexec,nosuid,nodev.
# /tmp becomes a tmpfs, /var/tmp a bind mount onto itself (systemd mount units). Application
# allowlisting (AppArmor/SELinux, code signing) is not enforced.
# Caveat: Nix builds that use /tmp as build directory need exec there; list
# "/tmp" in `keepExec` or point nix.settings.build-dir elsewhere. If you
# mount one of these paths yourself, list it in `keepExec` and set the
# options yourself.
import ../../lib/mkRequirement.nix {
  id = "KONF.7.10";

  options = lib: {
    keepExec = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "/tmp"
          "/var/tmp"
          "/dev/shm"
        ]
      );
      default = [ ];
      example = [ "/tmp" ];
      description = "Locations that are left untouched (execution stays possible).";
    };
    tmpSize = lib.mkOption {
      type = lib.types.str;
      default = "50%";
      description = "Size limit of the /tmp tmpfs (see mount(8), tmpfs size=).";
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
      guarded = path: !(builtins.elem path cfg.keepExec);
      flags = [
        "noexec"
        "nosuid"
        "nodev"
      ];
      e = import ../../lib/enforce.nix {
        inherit lib config;
        id = "KONF.7.10";
        items = [
          {
            # a systemd tmp.mount from useTmpfs would clash with our mount
            path = [
              "boot"
              "tmp"
              "useTmpfs"
            ];
            value = false;
            when = guarded "/tmp";
          }
          {
            # plain NixOS definition (priority 100) has to be extended
            path = [
              "boot"
              "specialFileSystems"
              "/dev/shm"
              "options"
            ];
            value = flags;
            priority = 100;
            ok = o: lib.all (f: builtins.elem f o) flags;
            expect = "containing ${lib.concatStringsSep "," flags}";
            when = guarded "/dev/shm";
          }
        ];
      };
      # Options of the systemd mount unit for `path`. Mount units (as in
      # nixpkgs boot.tmp.useTmpfs) are used instead of fileSystems because
      # NixOS VM tests replace the whole fileSystems attribute.
      mountOptions =
        path:
        lib.concatMap (m: lib.splitString "," (m.mountConfig.Options or "")) (
          lib.filter (m: m.where == path) config.systemd.mounts
        );
      mountUnit = what: where: type: options: {
        inherit what where type;
        mountConfig.Options = lib.concatStringsSep "," (flags ++ options);
        wantedBy = [ "local-fs.target" ];
        before = [ "local-fs.target" ];
      };
      mountAssertion = path: {
        assertion = !(guarded path) || lib.all (f: builtins.elem f (mountOptions path)) flags;
        message = "KONF.7.10: ${path} must be mounted with ${lib.concatStringsSep "," flags} (or list it in keepExec).";
      };
    in
    lib.mkMerge [
      e.settings
      {
        systemd.mounts =
          lib.optional (guarded "/tmp") (
            mountUnit "tmpfs" "/tmp" "tmpfs" [
              "mode=1777"
              "strictatime"
              "size=${cfg.tmpSize}"
            ]
          )
          ++ lib.optional (guarded "/var/tmp") (mountUnit "/var/tmp" "/var/tmp" "none" [ "bind" ]);
        assertions =
          e.assertions
          ++ map mountAssertion [
            "/tmp"
            "/var/tmp"
          ];
      }
    ];
}
