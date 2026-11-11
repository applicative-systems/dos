{
  name = "konf-2-5";

  containers.machine = {
    grundschutz.requirements."KONF.2.5".enable = true;
    system.configurationRevision = "0123456789abcdef0123456789abcdef01234567";
  };

  testScript = ''
    rev = machine.succeed("nixos-version --configuration-revision").strip()
    t.assertEqual(rev, "0123456789abcdef0123456789abcdef01234567")
  '';
}
