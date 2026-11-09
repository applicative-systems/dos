# NixOS test module (as consumed by pkgs.testers.runNixOSTest).
_: {
  name = "konf-2-4";

  nodes.machine = _: {
    grundschutz.requirements."KONF.2.4".enable = true;
  };

  nodes.keeps = _: {
    grundschutz.requirements."KONF.2.4" = {
      enable = true;
      keepKernelModules = [ "sctp" ];
      keepServices = [ "avahi" ];
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    keeps.wait_for_unit("multi-user.target")

    # disabled modules resolve to the "false" install command
    for mod in ["bluetooth", "firewire-core", "sctp", "cramfs"]:
        out = machine.succeed(f"modprobe -n -v {mod}")
        t.assertIn("false", out, f"{mod} is not disabled")

    # kept module is not blocked, other modules still are
    out = keeps.succeed("modprobe -n -v sctp")
    t.assertNotIn("false", out, "sctp should be kept")
    t.assertIn("false", keeps.succeed("modprobe -n -v bluetooth"))

    # services and default packages
    machine.fail("systemctl cat avahi-daemon.service")
    keeps.succeed("systemctl cat avahi-daemon.service")
    machine.fail("test -e /run/current-system/sw/bin/perl")
  '';
}
