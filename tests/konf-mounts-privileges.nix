{
  name = "konf-mounts-privileges";

  nodes = {
    machine =
      { pkgs, ... }:
      {
        grundschutz.requirements = {
          "KONF.3.8".enable = true;
          "KONF.6.4".enable = true;
          "KONF.7.10".enable = true;
        };
        users.users.alice = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          hashedPassword = "!";
        };
        users.users.bob = {
          isNormalUser = true;
          hashedPassword = "!";
        };
        environment.systemPackages = [ pkgs.util-linux ];
      };

    keeps.grundschutz.requirements."KONF.7.10" = {
      enable = true;
      keepExec = [ "/tmp" ];
    };

    run0.grundschutz.requirements."KONF.6.4" = {
      enable = true;
      privilegeEscalation = "run0";
    };

    nopass = {
      grundschutz.requirements."KONF.6.4" = {
        enable = true;
        allowPasswordlessSudo = true;
      };
      security.sudo.wheelNeedsPassword = false;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    keeps.wait_for_unit("multi-user.target")
    nopass.wait_for_unit("multi-user.target")
    run0.wait_for_unit("multi-user.target")

    def opts(node, path):
        return set(node.succeed(f"findmnt -T {path} -no OPTIONS").strip().split(","))

    with subtest("KONF.7.10 mount options"):
        for path in ["/tmp", "/var/tmp", "/dev/shm"]:
            o = opts(machine, path)
            t.assertLessEqual({"noexec", "nosuid", "nodev"}, o, path)

    with subtest("KONF.7.10 execution is refused"):
        for path in ["/tmp", "/var/tmp", "/dev/shm"]:
            machine.succeed(f"printf '#!/bin/sh\\necho hi\\n' > {path}/x.sh && chmod +x {path}/x.sh")
            status, out = machine.execute(f"{path}/x.sh 2>&1")
            t.assertNotEqual(status, 0, out)
            t.assertIn("Permission denied", out)
        # same script runs from an exec-capable location
        machine.succeed("printf '#!/bin/sh\\necho hi\\n' > /root/x.sh && chmod +x /root/x.sh && /root/x.sh")

    with subtest("KONF.7.10 keepExec"):
        keeps.succeed("printf '#!/bin/sh\\necho hi\\n' > /tmp/x.sh && chmod +x /tmp/x.sh && /tmp/x.sh")
        t.assertNotIn("noexec", opts(keeps, "/tmp"))
        t.assertIn("noexec", opts(keeps, "/dev/shm"))

    with subtest("KONF.6.4 sudo and su"):
        t.assertNotIn("NOPASSWD", machine.succeed("cat /etc/sudoers"))
        t.assertIn("NOPASSWD", nopass.succeed("cat /etc/sudoers"))
        # alice (wheel) can execute sudo, but the locked account has no password
        status, out = machine.execute("sudo -u alice sudo -n true 2>&1")
        t.assertNotEqual(status, 0)
        t.assertNotIn("Permission denied", out)
        # bob is not in wheel and cannot even execute sudo
        status, out = machine.execute("sudo -u bob /run/wrappers/bin/sudo -n true 2>&1")
        t.assertNotEqual(status, 0)
        t.assertIn("Permission denied", out)
        t.assertIn("pam_wheel", machine.succeed("cat /etc/pam.d/su"))

    with subtest("KONF.6.4 run0"):
        # no setuid sudo anywhere, polkit is the authority, bob gets no root
        run0.fail("test -e /run/wrappers/bin/sudo")
        run0.fail("test -e /run/wrappers/bin/sudo-rs")
        run0.succeed("systemctl cat polkit.service")
        status, _ = run0.execute("sudo -u bob run0 true 2>&1")
        t.assertNotEqual(status, 0)

    with subtest("KONF.3.8 no automounters"):
        for unit in ["udisks2.service", "devmon.service", "autofs.service"]:
            machine.fail(f"systemctl cat {unit}")
  '';
}
