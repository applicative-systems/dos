# Declares one Grundschutz++ requirement as a NixOS module.
#
#   mkRequirement { id = "KONF.7.15"; apply = { config, lib, pkgs, ... }: { ... }; }
#
# Options created: grundschutz.requirements.<id>.{enable,exempt}
# `apply` returns a normal NixOS config fragment (settings + assertions) that
# is only active when the requirement is enabled and not exempted.
{ id, apply }:
args@{ config, lib, ... }:
let
  cfg = config.grundschutz.requirements.${id};
in
{
  options.grundschutz.requirements.${id} = {
    enable = lib.mkEnableOption "Grundschutz++ requirement ${id}";
    exempt = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching ".+");
      default = null;
      example = "Handled by upstream firewall appliance, see risk assessment R-42";
      description = ''
        Documented reason for deviating from ${id}. While set, the
        requirement is not enforced and a warning is emitted.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.exempt == null) (apply args))
    (lib.mkIf (cfg.enable && cfg.exempt != null) {
      warnings = [ "Grundschutz++ ${id} is exempted: ${cfg.exempt}" ];
    })
  ];
}
