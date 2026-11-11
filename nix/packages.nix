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

  catalog = ../catalog/Grundschutz++-resolved_catalog.json;
  mapping = ../mapping/mapping.json;

  # { "KONF.2.2" = "Kryptographische Verfahren in IT-Systemen"; ... }:
  # groups and controls nest arbitrarily deep.
  titles =
    let
      collect =
        node:
        lib.optional (node ? id && node ? title) (lib.nameValuePair node.id node.title)
        ++ lib.concatMap collect (node.groups or [ ] ++ node.controls or [ ]);
    in
    lib.listToAttrs (collect (lib.importJSON catalog).catalog);

  mkOptionsDoc =
    {
      # prefix descriptions with a link to the requirement page
      linkRequirements ? false,
    }:
    pkgs.nixosOptionsDoc {
      options = eval.options.grundschutz;
      transformOptions =
        opt:
        let
          # loc: [ "grundschutz" "requirements" <id> <option> ... ]
          id = lib.elemAt opt.loc 2;
          # relative to options.md at the website root
          link = "[${id} ${titles.${id}}](requirements/${id}.md)";
        in
        opt
        // lib.optionalAttrs (linkRequirements && lib.length opt.loc > 3) {
          description = "Requirement ${link}.\n\n${opt.description or ""}";
        }
        // {
          # "Declared by": repository paths linked to GitHub instead of store
          # paths (plain strings would be rendered as <nixpkgs/...> links).
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

  # the requirement pages (docs) embed the plain descriptions
  optionsDoc = mkOptionsDoc { };
in
{
  # NixOS option reference of all requirement modules, rendered by
  # nixosOptionsDoc; descriptions link to the requirement pages of the website.
  modules-markdown = (mkOptionsDoc { linkRequirements = true; }).optionsCommonMark;

  # Markdown page per requirement of the groups with modules: our
  # interpretation, options (or why there is no module) and the original BSI
  # text (CC BY-SA, hence its own output).
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
