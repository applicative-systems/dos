{
  name = "konf-3-8";

  nodes.machine =
    { pkgs, ... }:
    {
      grundschutz.requirements."KONF.3.8" = {
        enable = true;
        automount = "noexec";
      };
      # what a desktop (GNOME, Plasma, fwupd) does
      services.udisks2.enable = true;
      virtualisation.emptyDiskImages = [
        64
        64
      ];
      environment.systemPackages = [
        pkgs.dosfstools
        pkgs.e2fsprogs
        pkgs.util-linux
      ];
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl cat udisks2.service")
    machine.fail("systemctl cat devmon.service")
    machine.fail("systemctl cat autofs.service")

    def check(fs, dev):
        machine.wait_until_succeeds(f"udevadm trigger --settle {dev} && udisksctl info -b {dev} | grep -E 'IdType: +{fs}$'", timeout=30)
        mnt = machine.succeed(f"udisksctl mount --no-user-interaction -b {dev}").split(" at ")[1].strip().rstrip(".")
        o = set(machine.succeed(f"findmnt -no OPTIONS {mnt}").strip().split(","))
        t.assertLessEqual({"noexec", "nosuid", "nodev"}, o, fs)
        machine.succeed(f"printf '#!/bin/sh\\necho hi\\n' > {mnt}/x.sh && chmod +x {mnt}/x.sh")
        status, out = machine.execute(f"{mnt}/x.sh 2>&1")
        t.assertNotEqual(status, 0, out)
        machine.succeed(f"udisksctl unmount --no-user-interaction -b {dev}")
        # requesting exec (or suid/dev) is refused
        for opt in ["exec", "suid", "dev"]:
            status, out = machine.execute(f"udisksctl mount --no-user-interaction -b {dev} -o {opt} 2>&1")
            t.assertNotEqual(status, 0, out)
            t.assertIn("OptionNotPermitted", out)

    with subtest("KONF.3.8 ext4 via udisks is noexec"):
        machine.succeed("mkfs.ext4 -q /dev/vdb")
        check("ext4", "/dev/vdb")

    with subtest("KONF.3.8 vfat via udisks is noexec"):
        machine.succeed("echo ,,c | sfdisk -q /dev/vdc && udevadm settle && mkfs.vfat /dev/vdc1")
        check("vfat", "/dev/vdc1")
  '';
}
