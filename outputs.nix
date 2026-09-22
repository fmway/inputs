{ self, ... }: let
  extraOutput = {
    "StarryReverie/selector4nix" = flake: let
      withSystem = system: fn:
        fn { config.packages = flake.packages.${system}; };
      config = import "${flake.outPath}/nix/flake/module.nix" {
        inherit withSystem config; 
        inputs = {}; self = {};
        flake-parts-lib.importApply = importApply;
      };
    in config.flake // rec {
      overlays = {
        selector4nix = _: super: {
          selector4nix = flake.packages.${super.stdenv.hostPlatform.system}.selector4nix;
        };
        default = overlays.selector4nix;
      };
    };
  };
  importApply =
    modulePath: staticArgs:
    {
      _file = modulePath;
      imports = [
        (import modulePath staticArgs)
      ];
    };
  collections = builtins.fromJSON (builtins.readFile ./dev/collections.json);
  keys = builtins.attrNames collections;
  
  lock = builtins.fromJSON (builtins.readFile ./dev/flake.lock);
  fetchInput = input: let
    locked = lock.nodes.${lock.nodes.root.inputs.${input}}.locked;
  in fetchTarball {
    url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.zip";
    sha256 = locked.narHash;
  };
  resolvedDev =
    (import (fetchInput "with-inputs")).from.flake ./dev {};

  allSystems = uniq (builtins.concatLists (builtins.catAttrs "systems" (builtins.attrValues collections)));

  uniq = xs: builtins.foldl' (acc: x: if acc != [ ] && builtins.elem x acc then acc else acc ++ [ x ]) [ ] xs;

  genAttrs = names: f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) names);

  # Refined data lives on the GitHub *release* (tag `data-yyyymmdd`, published
  # by dev/scripts/publish.sh), not in the repo — so this flake is input-less
  # and system-lazy: only the *.min.json for the system you read is fetched.
  # dev/data-lock.json pins the current release tag and the SRI hash of every
  # asset (local hash computed before upload, so it always matches).
  release = builtins.fromJSON (builtins.readFile ./dev/data-lock.json);

  fetchData =
    input: system:
    builtins.fetchurl {
      url = "https://github.com/fmway/inputs/releases/download/${release.tag}/${input}-${system}.min.json";
      sha256 = release.sha256."${input}-${system}";
    };

  mkOutputs =
    inputs: let
      flakes = genAttrs keys (key: let
        inherit (collections.${key}) systems inputName;
        flake = inputs.${inputName};
        packages = genAttrs systems (system:
          import ./lib/packages.nix {
            inherit system;
            dataFile = fetchData inputName system;
            original = inputs.${inputName}.packages.${system} or { };
          });
        outPath = fetchInput inputName;
      in {
        inherit (flake) sourceInfo outputs;
        inherit packages outPath;
      } // (
        if collections.${key} ? extraCaches then
          { extraCaches = collections.${key}.extraCaches; }
        else {}) // (
        if extraOutput ? ${key} then
          extraOutput.${key} { inherit packages outPath; }
        else {}));
      aliases = builtins.listToAttrs (builtins.concatMap (key: map (name: {
        inherit name;
        value = self.${key};
      }) (collections.${key}.aliases or [])) keys);
    in {
      inherit collections flakes aliases;
      packages = genAttrs allSystems (system:
        builtins.listToAttrs (builtins.concatMap (key: if self.${key}.packages ? ${system} then
          map (name: { inherit name; value = self.${key}.packages.${system}; }) ([key] ++ (collections.${key}.aliases or []))
        else []) keys));
    };
  r = resolvedDev mkOutputs;
  finalInputs = r.flakes // r.aliases;
in finalInputs // {
  inputs = finalInputs;
  inherit (r) collections packages;
}
