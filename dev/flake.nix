{
  description = "fmway/inputs dev flake — owns the collected input pins and the update tooling";

  inputs = {
    # core inputs
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    flake-compat.url = "github:nixos/flake-compat";
    flake-compat.flake = false;
    fmway-lib.url = "github:fmway/lib";
    fmway-lib.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    selector4nix.url = "github:StarryReverie/selector4nix";
    chaotic.url = "github:chaotic-cx/nyx";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
    direnv-instant.url = "github:Mic92/direnv-instant/1.3.0";

    # artcraft
    filmcraft.url = "github:storytold/filmcraft/v0.8.0";
    filmcraft.flake = false;
  };

  outputs =
    { self, nixpkgs, ... } @ inputs:
    let
      overrideInput = {
        chaotic = { self, ... }: {
          packages = self.unrestrictedPackages;
        };
      };

      overrideBuilders = {
        artcraft.pdfcraft = self:
          self.overrideAttrs (old: let
            attributions = fromTOML (builtins.readFile "${old.src}/ATTRIBUTION.toml");
          in {
            postInstall = old.postInstall or "" + lib.concatMapStrings (x: /* sh */ ''
              cp "${builtins.fetchurl { inherit (x) url sha256; }}" "$out/share/$pname/${x.file}"
              cp "${builtins.fetchurl { url = x.license_url; sha256 = x.license_sha256; }}" "$out/share/$pname/${x.file}.LICENSE.txt"
            '') (builtins.filter (x: x.kind == "model") attributions.fetched);
          });

        # TODO: add driver support
        artcraft.filmcraft = self:
          self.overrideAttrs (o: {
            patches = o.patches or [] ++ [
              ./patches/no-ensure-desktop-filmcraft.patch
            ];
           });
      };

      builders = {
        artcraft = system: { inputName, ... }:
          nixpkgs.legacyPackages.${system}.callPackage ./artcraft.nix {
            name = inputName;
            source = inputs.${inputName};
          };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

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
    in {
      inherit collections namespaces;
      inputs =
        builtins.mapAttrs (k: v: v // (if overrideInput ? ${k} then overrideInput.${k} ({ self = v.sourceInfo // v.outputs; } // v.inputs) else {})) inputs
        //
        builtins.mapAttrs (namespace: systems: {
          packages = lib.genAttrs systems (system:
            builtins.mapAttrs (name: x:
              overrideBuilders.${namespace}.${name} or (x: x)
                (builders.${namespace} system x)
            ) (lib.filterAttrs (_: v: v.namespace or "" == namespace) collections)
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
        readme.program = "${lib.fmway.parse.mkScript pkgs { inherit collections namespaces lib; source = ../README.md; }}";

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
