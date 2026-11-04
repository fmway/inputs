{ inputs, lib, namespaces, systems, collections, ... }: let
  getSupportedSystems = ns: name:
    builtins.filter (system: inputs ? ${ns}.packages.${system}.${name}) systems;
in {
  custom-namespace-section = if namespaces == {} then "" else
    "### Custom namespaces\n" + builtins.concatStringsSep "" (builtins.concatMap (ns:
      map (name: let pkg = inputs.${ns}.packages.x86_64-linux.${name}; in /* markdown */ ''
        <details>
          <summary>${ns}.${name}</summary>

          ${builtins.concatStringsSep "\n  " (
          lib.optional (pkg ? meta.homepage)
            "- **Homepage**: ${pkg.meta.homepage}"
          ++ lib.optional (pkg ? meta.description)
            "- **Description**: ${pkg.meta.description}"
          ++ [
            "- **License**: ${lib.concatMapStringsSep ", " (l: l.spdxId) (lib.fmway.flat pkg.meta.license)}"
            "- **Supported Systems**: ${builtins.concatStringsSep ", " (getSupportedSystems ns name)}"
            "- **Usage**: `nix run github:fmway/inputs#${ns}.${name} -- [...]`"
          ])}
        </details>
      ''
      ) (builtins.attrNames inputs.${ns}.packages.x86_64-linux)
    ) (builtins.attrNames namespaces));

  current-flakes-section = if collections == {} then "" else
    "### Current flakes\n" + lib.concatMapAttrsStringSep "\n" (k: v:
      "- [${k}](${v.repo})" + lib.optionalString (v.aliases or [] != []) " (alias: ${builtins.concatStringsSep ", " v.aliases})"
    ) (lib.filterAttrs (_: v: !v?namespace) collections);
}
