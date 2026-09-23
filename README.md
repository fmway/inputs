# fmway/inputs (AI Assisted)

Personal collection of flake **inputs** rerouted through
fake derivations, so consuming their packages doesn't drag each upstream
nixpkgs closure into your own flake.

## Current flakes:
<!--{% (_: lib.concatMapAttrsStringSep "\n" (k: v: "- [${k}](${v.repo})" + lib.optionalString (v.aliases or [] != []) " (alias: ${builtins.concatStringsSep ", " v.aliases})") collections) %}-->
- [StarryReverie/selector4nix](https://github.com/StarryReverie/selector4nix) (alias: selector4nix)
- [chaotic-cx/nyx](https://github.com/chaotic-cx/nyx) (alias: chaotic)
- [moku-project/moku](https://github.com/moku-project/moku) (alias: moku)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) (alias: llm-agents)
<!--{% end %}-->

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    fmway-inputs.url = "github:fmway/inputs";
  };

  outputs = { fmway-inputs, nixpkgs, ... }: {
    igloo = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            # Same shape as the original flake's output, but cached packages are
            # light fake derivations. Uncached ones are the real derivations.
            # Either orientation works:
            fmway-inputs."numtide/llm-agents.nix".packages.${system}.opencode
            # fmway-inputs.packages.${system}."numtide/llm-agents.nix".opencode;
          ];
        })
      ];
    };
  };
}
```

For a fake (cached) package:

```sh
nix shell '.#llm-agents.opencode.out'
nix build '.#llm-agents.opencode.orig'   # real derivation
nix build '.#llm-agents.apm'             # some are uncached → build locally
```

Fake derivations merely serve already-built store outputs — they have no `.drv`
of their own (`drvPath` throws). The real upstream derivation is always
available under `.orig`.

### Where the data comes from

Each input's refined package data is published to a GitHub **release** tagged
`data-YYYYMMDD` (one `<input>-<system>.min.json` asset per system, overwritten
in place when the daily pipeline re-runs). The flake declares no inputs and
fetches lazily: evaluating `packages.x86_64-linux` downloads only the
`x86_64-linux` asset — an `aarch64-linux` eval never pulls `x86_64-linux`
data. `dev/data-lock.json` pins the current release tag and the SRI hash of
every asset.

## Adding an input

1. Declare it in `inputs` in `dev/flake.nix` and run `nix flake lock` in `./dev`.
2. Map the public output key → input name in `dev/collections.json`
   (`inputName`, `repo`, `systems`, plus optional `aliases`, `extraCaches`, and
   `tags = true` for release-tagged inputs).
3. Run `nix run ./dev#refresh`, `nix run ./dev#publish` (uploads the data
   release, needs `gh`), `nix run ./dev#readme README.md`, and
   `nix run ./dev#flake flake.nix`, then commit `dev/data-lock.json` and the
   other changed files.

## Requirements

- `nix` with `nix-command` and `flakes`
- Everything else (`jq`, `nix-eval-jobs`) comes from the dev flake's nixpkgs
  via `apps`/`devShells` — nothing needs to be installed on the host.

## References
- https://github.com/tomberek/fastpkgs
- https://github.com/fzakaria/nixpkgs-multiverse
- https://nixmultiverse.com/docs/store-paths
