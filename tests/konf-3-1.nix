{
  name = "konf-3-1";

  nodes.machine =
    { pkgs, ... }:
    {
      grundschutz.requirements."KONF.3.1".enable = true;
      # emulated TPM 2.0 (swtpm)
      virtualisation.tpm.enable = true;
      environment.systemPackages = [ pkgs.tpm2-tools ];
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # the TPM resource manager device belongs to the tss group (security.tpm2)
    machine.wait_for_file("/dev/tpmrm0")
    t.assertEqual(machine.succeed("stat -c %G /dev/tpmrm0").strip(), "tss")

    # and the TPM is usable
    machine.succeed("tpm2_getrandom --hex 16 -T device:/dev/tpmrm0")
  '';
}
