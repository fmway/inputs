{
  description = "fmway/inputs dev flake — owns the collected input pins and the update tooling";

  inputs = {
    # core inputs
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    flake-compat.url = "github:nixos/flake-compat";
    flake-compat.flake = false;
    fmway-lib.url = "github:fmway/lib";
    fmway-lib.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane/v0.24.0";

    llm-agents.url = "github:numtide/llm-agents.nix";
    selector4nix.url = "github:StarryReverie/selector4nix";
    chaotic.url = "github:chaotic-cx/nyx";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
    direnv-instant.url = "github:Mic92/direnv-instant/1.3.0";
    concat.url = "github:jub0t/concat/v0.2.8";
    concat.inputs.nixpkgs.follows = "nixpkgs";
    maki.url = "github:tontinton/maki/v0.6.5";
    maki.inputs.nixpkgs.follows = "nixpkgs";
    maki.inputs.crane.follows = "crane";
    maki.inputs.rust-overlay.follows = "rust-overlay";

    # artcraft
    cadcraft.url = "github:storytold/cadcraft/v0.15.1";
    cadcraft.flake = false;
    deckcraft.url = "github:storytold/deckcraft/v0.13.1";
    deckcraft.flake = false;
    designcraft.url = "github:storytold/designcraft/v0.15.2";
    designcraft.flake = false;
    effectcraft.url = "github:storytold/effectcraft/v0.19.0";
    effectcraft.flake = false;
    figcraft.url = "github:storytold/figcraft/v0.13.1";
    figcraft.flake = false;
    filmcraft.url = "github:storytold/filmcraft/v0.15.0";
    filmcraft.flake = false;
    gridcraft.url = "github:storytold/gridcraft/v0.14.2";
    gridcraft.flake = false;
    lightcraft.url = "github:storytold/lightcraft/v0.16.0";
    lightcraft.flake = false;
    pdfcraft.url = "github:storytold/pdfcraft/v0.16.1";
    pdfcraft.flake = false;
    photocraft.url = "github:storytold/photocraft/v0.18.0";
    photocraft.flake = false;
    soundcraft.url = "github:storytold/soundcraft/v0.15.0";
    soundcraft.flake = false;
    vectorcraft.url = "github:storytold/vectorcraft/v0.19.0";
    vectorcraft.flake = false;
    wordcraft.url = "github:storytold/wordcraft/v0.13.2";
    wordcraft.flake = false;
  };

  outputs =
    { self, nixpkgs, rust-overlay, ... } @ inputs:
    let
      overrideInput = {
        chaotic = { self, ... }: {
          packages = self.unrestrictedPackages;
        };
      };

      builders = let
        parseYaml = file:
          lib.yaml.parse {} (builtins.readFile file);
      in {
        # default builder, only reroute to the regular packages
        __functor = _: system: inputName:
          (parseInput inputName inputs.${inputName}).packages.${system};

        artcraft = let
          craneLibFor = system:
            inputs.crane.mkLib nixpkgs.legacyPackages.${system};

          mkArtcraft = craneLib: system: { inputName, ... }:
            nixpkgs.legacyPackages.${system}.callPackage ./artcraft.nix {
              inherit craneLib parseYaml;
              name = inputName;
              # temp fix: pin some deps until they update it
              source = let
                src = inputs.${inputName};
                patched = nixpkgs.legacyPackages.${system}.runCommand "${inputName}-patched-source" {} ''
                  cp -r ${src} $out
                  chmod -R +w $out
                  find "$out" -type f \( -name Cargo.toml -o -name Cargo.lock \) -print0 |
                    while IFS= read -r -d "" f; do
                      substituteInPlace "$f" \
                        --replace-warn "${patches.craft-libs.old}" "${patches.craft-libs.new}" \
                        --replace-warn "${patches.egui-git.old}" "${patches.egui-git.new}"
                    done
                '';
              in patched // { inherit (src) lastModifiedDate; };
            };
        in {
          __functor = _: system:
            mkArtcraft (craneLibFor system) system;

          pdfcraft = system: { inputName, ... }: let
            pkgs = nixpkgs.legacyPackages.${system};
            craneLib = # need latest rustc in x86_64-linux
              if system == "x86_64-linux" then
                (inputs.crane.mkLib pkgs).overrideToolchain (p:
                  (rust-overlay.lib.mkRustBin {} p).fromRustupToolchain { channel = "stable"; })
              else craneLibFor system;
            self = mkArtcraft craneLib system { inherit inputName; };
          in self.overrideAttrs (old: let
              attributions = fromTOML (builtins.readFile "${old.src}/ATTRIBUTION.toml");
            in {
              postInstall = old.postInstall or "" + lib.concatMapStrings (x: /* sh */ ''
                install -Dm644 "${builtins.fetchurl { inherit (x) url sha256; }}" "$out/share/$pname/${x.file}"
                install -Dm644 "${builtins.fetchurl {
                  url = x.license_url or x.licence_url;
                  sha256 = x.license_sha256 or x.licence_sha256;
                }}" "$out/share/$pname/${x.file}.LICENSE.txt"
              '') (builtins.filter (x: x.kind == "model") attributions.fetched);
            });

          filmcraft = system: { inputName, ... }:
            (mkArtcraft (craneLibFor system) system { inherit inputName; }).overrideAttrs (o: {
              patches = o.patches or [] ++ [
                ./patches/no-ensure-desktop-filmcraft.patch
              ];
              runtimeDependencies = [
                nixpkgs.legacyPackages.${system}.libva
              ];
             });
        };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      patches = {
        craft-libs = { old = "92d392cff132eaf53e13afff77f38b5c11b73aa0"; new = "1a11a4897865f7410c40d25ca6e452ce399a1a2c"; };
        egui-git   = { old = "6d518fc799681571963842f95b55a6b68431b15a"; new = "310f43c5c003eee784b8a302a0c70c2985c04bfb"; };
      };

      # { <namespace> = unique <systems>; }
      namespaces = lib.select "(**(namespace)).*.**1.systems.**" collections;
      forAllSystems = lib.genAttrs systems;
      collections = builtins.fromJSON (builtins.readFile ./collections.json);
      lib = nixpkgs.lib.extend inputs.fmway-lib.overlays.default;
      flake = {
        description = "fmway/inputs — clean, input-less flake rerouting collected flake inputs through fake derivations";

        inputs.__doc = [
          "Empty by design: the ./dev flake owns every pin and its lock is resolved"
          "into inputs here at eval time, so this flake never writes a flake.lock."
        ];
        outputs.__raw = "inputs: import ./default.nix";
        nixConfig = builtins.zipAttrsWith (_: v: lib.unique (builtins.concatLists v))
          ((lib.select "**.??extraCaches.{?substituters:extra-substituters,?trusted-public-keys:extra-trusted-public-keys}" collections) ++ [
            {
              extra-trusted-substituters = [
                "https://fmcachix.cachix.org"
              ];
              extra-trusted-public-keys = [
                "fmcachix.cachix.org-1:Z5j9jk83ctoCK22EWrbQL6AAP3CTYnZ/PHljlYSakrw="
              ];
            }
          ]);
      };
      parseInput = inputName: source:
        lib.fix (self: source // overrideInput.${inputName} or (_: {}) ({ inherit self; } // source.inputs));
    in {
      inherit collections namespaces;
      inputs =
        builtins.mapAttrs parseInput inputs
        //
        builtins.mapAttrs (namespace: systems: let
          filteredCollections = lib.filterAttrs (_: v: v.namespace or "" == namespace) collections;
          collect = if builders ? ${namespace} then builtins.mapAttrs else fn: lib.foldlAttrs (a: k: v: lib.recursiveUpdate a (fn k v)) {};
        in {
          packages = lib.genAttrs systems (system:
            collect (name: x:
              builders.${namespace}.${name} or builders.${namespace} or builders system x
            ) filteredCollections
          );
        }) namespaces
        ;
      apps = forAllSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        refresh.type = "app";
        refresh.program = let
          pkg = pkgs.writeShellApplication {
            name = "refresh";
            runtimeInputs = with pkgs; [ jq nix-eval-jobs ];
            text = "exec \"${./scripts/refresh.sh}\"";
          };
        in "${pkg}/bin/refresh";

        publish.type = "app";
        publish.program = let
          pkg = pkgs.writeShellApplication {
            name = "publish";
            runtimeInputs = with pkgs; [ jq gh ];
            text = "exec \"${./scripts/publish.sh}\"";
          };
        in "${pkg}/bin/publish";

        readme.type = "app";
        readme.program = "${lib.template.v2.mkScript pkgs {
          file = ../README.md;
          scope = rec {
            inherit collections namespaces lib;
            genListCustomPackage = namespace:
              lib.concatMapStringsSep "\n" (k:
                "- [${k}](${collections.${k}.repo})"
              ) (builtins.filter (x: collections.${x}.namespace or "" == namespace) (builtins.attrNames collections));
            custom_packages = lib.concatMapAttrsStringSep "" (namespace: _: ''
              <details>
                <summary>${namespace}</summary>

                ${genListCustomPackage namespace}
              </details>
            '') namespaces;
          };
        }}";

        flake.type = "app";
        flake.program = "${lib.fmway.genNix.mkScript pkgs flake}";
      });

      devShells = forAllSystems (
        system:
        {
          default = nixpkgs.legacyPackages.${system}.mkShell {
            packages = with nixpkgs.legacyPackages.${system}; [
              jq
              nix-eval-jobs
              nix
            ];
          };
        }
      );
    };
}
