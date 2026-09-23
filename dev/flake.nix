{
  description = "fmway/inputs dev flake — owns the collected input pins and the update tooling";

  inputs = {
    # core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    with-inputs.url = "github:denful/with-inputs";
    with-inputs.flake = false;
    fmway-lib.url = "github:fmway/lib";
    fmway-lib.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    moku.url = "github:moku-project/moku/v0.13.1";
    selector4nix.url = "github:StarryReverie/selector4nix";
    chaotic.url = "github:chaotic-cx/nyx";
  };

  outputs =
    { self, nixpkgs, ... } @ inputs:
    let
      overrideInput = {
        chaotic = { self, ... }:
        {
          packages = let
            packageNames = lib.unique (map (s:
              if lib.hasInfix "." s then builtins.head (lib.splitString "." s) else s) (builtins.attrNames self.packages.x86_64-linux));
          in lib.genAttrs systems (system: lib.genAttrs packageNames (pname: self.unrestrictedPackages.${system}.${pname}));
        };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = lib.genAttrs systems;
      collections = builtins.fromJSON (builtins.readFile ./collections.json);
      lib = nixpkgs.lib.extend inputs.fmway-lib.overlays.default;
      flake = {
        description = "fmway/inputs — clean, input-less flake rerouting collected flake inputs through fake derivations";

        inputs.__doc = [
          "Empty by design: the ./dev flake owns every pin and its lock is resolved"
          "into inputs here at eval time, so this flake never writes a flake.lock."
        ];
        outputs.__raw = "inputs: import ./outputs.nix inputs";
        nixConfig = builtins.zipAttrsWith (_: v: lib.unique (builtins.concatLists v))
          (lib.select "**.??extraCaches.{?substituters:extra-substituters,?trusted-public-keys:extra-trusted-public-keys}" collections);
      };
    in {
      inherit collections;
      inputs = builtins.mapAttrs (k: v: v // (if overrideInput ? ${k} then overrideInput.${k} ({ self = v.sourceInfo // v.outputs; } // v.inputs) else {})) inputs;
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
        readme.program = let
          var = { prefix = "<!--{"; postfix = "}-->"; inherit collections lib; };
          txt = lib.fmway.mkParse' var (builtins.readFile ../README.md);
          pkg = pkgs.writeScript "gen-readme.sh" /* bash */ ''
            #!${lib.getExe pkgs.bash}

            output="''${1:-/dev/stdout}"
            cat ${pkgs.writeText "README.md" txt} > $output
          '';
        in "${pkg}";

        flake.type = "app";
        flake.program = "${pkgs.writeScript "gen-flake.sh" /* bash */ ''
          #!${lib.getExe pkgs.bash}

          output="''${1:-/dev/stdout}"
          cat ${pkgs.writeText "flake.nix" (lib.fmway.genNix flake)} > $output
        ''}";
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
