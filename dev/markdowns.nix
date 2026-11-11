{ inputs, lib, namespaces, systems, collections, ... }: let
  getSupportedSystems = ns: name:
    builtins.filter (system: inputs ? ${ns}.packages.${system}.${name}) systems;
  get-short-desc = desc:
    trim (sed { extended_regex = true; quiet = true; } ''s/^(([^.!?]*([0-9]\.[0-9])[^.!?]*)*[^.!?]*)[.!?]?([ ]|$).*/\1/p; q'' desc);

  inherit (lib) trim sed;
in {
  custom-namespace-section = if namespaces == {} then "" else
    "### Custom namespaces\n" + builtins.concatStringsSep "" (builtins.concatMap (ns:
      map (name: let pkg = inputs.${ns}.packages.x86_64-linux.${name}; in /* markdown */ ''
        <details>
          <summary><strong>${ns}.${name}</strong>${if pkg ? meta.description then " - ${get-short-desc pkg.meta.description}" else ""}</summary>

          ${builtins.concatStringsSep "\n  " ([
            "- **Version**: ${pkg.version}"
          ] ++ lib.optional (pkg ? meta.homepage)
            "- **Homepage**: ${pkg.meta.homepage}"
          ++ lib.optional (pkg ? meta.license)
            "- **License**: ${lib.concatMapStringsSep ", " (l: l.spdxId) (lib.fmway.flat pkg.meta.license)}"
          ++ [
            "- **Supported Systems**: ${builtins.concatStringsSep ", " (getSupportedSystems ns name)}"
            "- **Usage**: `nix shell github:fmway/inputs#${ns}.${name}.out -c [...]`"
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
