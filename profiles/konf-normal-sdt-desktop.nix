# konf-normal-sdt for desktops and laptops: the same requirements, with the
# interpretations that a graphical workstation needs.
# - KONF.3.8: udisks2/gvfs may mount removable media, but only noexec,nosuid,
#   nodev. GNOME, Plasma and fwupd enable udisks2, which the server
#   interpretation forbids.
# Everything listed in ./konf-normal-sdt.nix still has to be provided.
# Typical per-host settings on top:
# - KONF.2.4: keepServices = [ "bluetooth" "printing" "avahi" ] as needed
# - KONF.2.5: allowDirty when rebuilding from an uncommitted working tree
# - KONF.6.4: privilegeEscalation = "run0" if the host uses run0
# - KONF.8.2: system.autoUpgrade.operation = "switch" to update without
#   rebooting the machine under its user
{ lib, ... }:
{
  imports = [ ./konf-normal-sdt.nix ];
  grundschutz.requirements."KONF.3.8".automount = lib.mkDefault "noexec";
}
