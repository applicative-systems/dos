{
  self,
  lib,
  pkgs,
}:
let
  helpers = import ./eval.nix { inherit lib; };
  # Options do not depend on the target platform; any Linux will do.
  eval = helpers.evalSystem "x86_64-linux" [ self.nixosProfiles.konf-normal-sdt ];
  reqs = eval.config.grundschutz.requirements;

  optionsDoc = pkgs.nixosOptionsDoc {
    options = eval.options.grundschutz;
    # "Declared by": repository paths linked to GitHub instead of store paths
    # (plain strings would be rendered as <nixpkgs/...> links).
    transformOptions =
      opt:
      opt
      // {
        declarations = map (
          d:
          let
            name = helpers.repoPath d;
          in
          {
            inherit name;
            url = "https://github.com/applicative-systems/dos/blob/${self.rev or "main"}/${name}";
          }
        ) opt.declarations;
      };
  };

  catalog = ../catalog/Grundschutz++-resolved_catalog.json;
  mapping = ../mapping/mapping.json;
in
{
  # NixOS option reference of all requirement modules, rendered by nixosOptionsDoc.
  modules-markdown = optionsDoc.optionsCommonMark;

  # Markdown documentation of every requirement module: our interpretation,
  # options and the original BSI text (CC BY-SA, hence its own output).
  docs =
    let
      facts = builtins.toFile "facts.json" (
        builtins.toJSON {
          declared = lib.attrNames reqs;
          profiles.konf-normal-sdt = lib.attrNames (lib.filterAttrs (_: r: r.enable) reqs);
        }
      );
    in
    pkgs.runCommand "grundschutz-docs" { nativeBuildInputs = [ pkgs.jq ]; } ''
      mkdir $out
      jq -c \
        --slurpfile m ${mapping} \
        --slurpfile o ${optionsDoc.optionsJSON}/share/doc/nixos/options.json \
        --slurpfile f ${facts} \
        -f ${../tools/docs.jq} ${catalog} \
        | while IFS= read -r page; do
            jq -r .text <<<"$page" > "$out/$(jq -r .file <<<"$page")"
          done
    '';

  # docs/STATUS.md: every catalog control joined with the mapping
  status = pkgs.runCommand "STATUS.md" {
    nativeBuildInputs = [ pkgs.jq ];
  } "jq -r --slurpfile m ${mapping} -f ${../tools/status.jq} ${catalog} > $out";
}
