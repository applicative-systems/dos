{
  name = "konf-4-5";

  nodes.machine =
    { lib, ... }:
    {
      grundschutz.requirements."KONF.4.5" = {
        enable = true;
        allowedTimeServers = [
          "ntp1.example.org"
          "ntp2.example.org"
        ];
      };
      # the test instrumentation disables timesyncd
      services.timesyncd.enable = lib.mkForce true;
    };

  testScript = ''
    machine.wait_for_unit("systemd-timesyncd.service")

    # timesyncd uses exactly the authorized servers, also as fallback
    out = machine.succeed("timedatectl show-timesync -p SystemNTPServers -p FallbackNTPServers")
    t.assertIn("SystemNTPServers=ntp1.example.org ntp2.example.org", out)
    t.assertIn("FallbackNTPServers=ntp1.example.org ntp2.example.org", out)
    t.assertNotIn("nixos.pool.ntp.org", out)
  '';
}
