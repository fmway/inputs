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
      };

      builders = {
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # { <groupName> = unique <systems>; }
      groups = lib.select "(**(group)).*.**1.systems.**" collections;
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
      inherit collections groups;
      inputs =
        builtins.mapAttrs (k: v: v // (if overrideInput ? ${k} then overrideInput.${k} ({ self = v.sourceInfo // v.outputs; } // v.inputs) else {})) inputs
        //
        builtins.mapAttrs (group: systems: {
          packages = lib.genAttrs systems (system:
            builtins.mapAttrs (name: x:
              overrideBuilders.${group}.${name} or (x: x)
                (builders.${group} system x)
            ) (lib.filterAttrs (_: v: v.group or "" == group) collections)
          );
        }) groups
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
        readme.program = "${lib.fmway.parse.mkScript pkgs { inherit collections groups lib; source = ../README.md; }}";

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
