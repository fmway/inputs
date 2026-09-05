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
    # Add the next collected input here:
    # some-input.url = "github:owner/repo";
  };

  outputs =
    { self, nixpkgs, fmway-lib, ... } @ inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = lib.genAttrs systems;
      collections = builtins.fromJSON (builtins.readFile ./collections.json);
      inherit (nixpkgs) lib;
    in {
      inherit inputs collections;
      apps = forAllSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        refresh.type = "app";
        refresh.program = let
          pkg = pkgs.writeShellApplication {
            name = "refresh";
            runtimeInputs = with pkgs; [ jq nix-eval-jobs nix ];
            text = "exec \"${./scripts/refresh.sh}\"";
          };
        in "${pkg}/bin/refresh";

        readme.type = "app";
        readme.program = let
          var = { prefix = "<!--{"; postfix = "}-->"; inherit collections lib; };
          txt = fmway-lib.fmway.mkParse' var (builtins.readFile ../README.md);
          pkg = pkgs.writeScript "gen-readme.sh" /* bash */ ''
            #!${lib.getExe pkgs.bash}

            output="''${1:-/dev/stdout}"
            cat ${pkgs.writeText "README.md" txt} > $output
          '';
        in "${pkg}";
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
