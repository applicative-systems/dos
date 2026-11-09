# Enables all implemented KONF requirements of level "normal-SdT".
{ lib, ... }:
{
  imports = [ ../modules ];
  grundschutz.requirements = {
    "KONF.2.3".enable = lib.mkDefault true;
    "KONF.2.4".enable = lib.mkDefault true;
    "KONF.7.15".enable = lib.mkDefault true;
    "KONF.7.16".enable = lib.mkDefault true;
  };
}
