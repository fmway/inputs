{ self, ... }: let
  collection = builtins.fromJSON (builtins.readFile ./dev/collections.json);
  keys = builtins.attrNames collection;

  resolvedDev = let
    lock = builtins.fromJSON (builtins.readFile ./dev/flake.lock);
    locked = lock.nodes.with-inputs.locked;
    with-inputs = fetchTarball {
      url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.zip";
      sha256 = locked.narHash;
    };
  in (import with-inputs).from.flake ./dev (_: { nixpkgs-lib.follows = "nixpkgs"; });

  allSystems = uniq (builtins.concatLists (builtins.catAttrs "systems" (builtins.attrValues collection)));

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
        inherit (collection.${key}) systems inputName;
        flake = inputs.${inputName};
        packages = genAttrs systems (system:
          import ./lib/packages.nix {
            inherit system;
            dataFile = fetchData inputName system;
            original = inputs.${inputName}.packages.${system} or { };
          });
      in {
        inherit (flake) sourceInfo outputs;
        inherit packages;
      } // (
        if collection.${key} ? extraCaches then
          { extraCaches = collection.${key}.extraCaches; }
        else {}));
      aliases = builtins.listToAttrs (builtins.concatMap (key: map (name: {
        inherit name;
        value = self.${key};
      }) (collection.${key}.aliases or [])) keys);
    in flakes // aliases // {
      inherit inputs;
      packages = genAttrs allSystems (system:
        builtins.listToAttrs (builtins.concatMap (key: if self.${key}.packages ? ${system} then
          map (name: { inherit name; value = self.${key}.packages.${system}; }) ([key] ++ (collection.${key}.aliases or []))
        else []) keys));
    };
in (resolvedDev mkOutputs)
