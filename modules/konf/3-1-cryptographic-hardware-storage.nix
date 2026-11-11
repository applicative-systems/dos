# KONF.3.1 Kryptographischer Hardwarespeicher (normal-SdT, SOLLTE)
# Interpretation: a TPM 2.0 is the cryptographic hardware storage of a server.
# The TPM2 stack is enabled and asserted (security.tpm2: udev rules, `tss`
# group owning /dev/tpmrm0), so services and systemd-cryptenroll/-creds can use it.
# Hardware without TPM, or VMs without vTPM, set the requirement exempt.
# Status "partial": whether a TPM is actually present and whether keys are
# stored in it (LUKS via systemd-cryptenroll --tpm2, systemd-creds, PKCS#11)
# cannot be seen at evaluation time.
import ../../lib/mkRequirement.nix {
  id = "KONF.3.1";
  apply =
    { config, lib, ... }:
    {
      # Priority 900 beats the NixOS default but not a plain user definition.
      security.tpm2.enable = lib.mkOverride 900 true;

      assertions = [
        {
          assertion = config.security.tpm2.enable;
          message = "KONF.3.1: security.tpm2.enable must be true (or set grundschutz.requirements.\"KONF.3.1\".exempt, e.g. for hardware without TPM).";
        }
      ];
    };
}
