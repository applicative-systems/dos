# Declares one Grundschutz++ requirement as a NixOS module.
#
#   mkRequirement { id = "KONF.7.15"; apply = { config, lib, pkgs, cfg, ... }: { ... }; }
#
# Options created: grundschutz.requirements.<id>.{enable,exempt} plus any
# requirement-specific `options` (a function of `lib`). `apply` returns a normal NixOS config
# fragment (settings + assertions) that is only active when the requirement
# is enabled and not exempted. It receives the usual module args plus `cfg`
# (the requirement's own option values).
{
  id,
  options ? _lib: { },
  apply,
}:
args@{
  config,
  lib,
  pkgs,
  ...
}:
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
  }
  // options lib;

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.exempt == null) (apply (args // { inherit cfg pkgs; })))
    (lib.mkIf (cfg.enable && cfg.exempt != null) {
      warnings = [ "Grundschutz++ ${id} is exempted: ${cfg.exempt}" ];
    })
  ];
}
