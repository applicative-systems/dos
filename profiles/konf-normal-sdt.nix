# Enables all implemented KONF requirements of level "normal-SdT".
{ lib, ... }: {
  imports = [ ../modules ];
  grundschutz.requirements = {
    "KONF.7.15".enable = lib.mkDefault true;
    "KONF.2.3".enable = lib.mkDefault true;
  };
}
