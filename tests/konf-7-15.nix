{
  name = "konf-7-15";

  containers.machine = {
    grundschutz.requirements."KONF.7.15".enable = true;
  };

  testScript = ''
    machine.wait_for_unit("firewall.service")
    machine.succeed("iptables -S | grep -q nixos-fw")
  '';
}
