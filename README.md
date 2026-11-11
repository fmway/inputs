# fmway/inputs (AI Assisted)

Personal collection of flake **inputs** rerouted through
fake derivations, so consuming their packages doesn't drag each upstream
nixpkgs closure into your own flake.

<!--{% markdowns.current-flakes-section %}-->
### Current flakes
- [Mic92/direnv-instant](https://github.com/Mic92/direnv-instant) (alias: direnv-instant)
- [StarryReverie/selector4nix](https://github.com/StarryReverie/selector4nix) (alias: selector4nix)
- [chaotic-cx/nyx](https://github.com/chaotic-cx/nyx) (alias: chaotic)
- [daeuniverse](https://github.com/daeuniverse/flake.nix)
- [manic-systems/evix](https://github.com/manic-systems/evix) (alias: evix)
- [nix-community/lanzaboote](https://github.com/nix-community/lanzaboote) (alias: lanzaboote)
- [numtide/iets](https://github.com/numtide/iets) (alias: iets)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) (alias: llm-agents)
- [psyclyx/fix](https://github.com/psyclyx/fix) (alias: fix)
<!--{% end %}-->

<!--{% markdowns.custom-namespace-section %}-->
### Custom namespaces
<details>
  <summary><strong>agents.maki</strong></summary>

  - **Version**: 0.7.1
  - **Supported Systems**: x86_64-linux, aarch64-linux, aarch64-darwin
  - **Usage**: `nix shell github:fmway/inputs#agents.maki.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.cadcraft</strong> - Open-source computer-aided design and drafting: draft, dimension and plot 2D</summary>

  - **Version**: 0.19.0
  - **Homepage**: https://getartcraft.com/apps/cadcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.cadcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.deckcraft</strong> - Open-source, native presentation app that works the way PowerPoint users</summary>

  - **Version**: 0.17.0
  - **Homepage**: https://getartcraft.com/apps/deckcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.deckcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.designcraft</strong> - Open-source, native page layout and publishing that works the way InDesign users expect</summary>

  - **Version**: 0.19.0
  - **Homepage**: https://getartcraft.com/apps/designcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.designcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.effectcraft</strong> - Open-source motion graphics and visual effects compositor</summary>

  - **Version**: 0.23.1
  - **Homepage**: https://getartcraft.com/apps/effectcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.effectcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.figcraft</strong> - Open-source, native interface design and prototyping tool</summary>

  - **Version**: 0.17.0
  - **Homepage**: https://getartcraft.com/apps/figcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.figcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.filmcraft</strong> - Open-source, native video editor: edit video, color and sound</summary>

  - **Version**: 0.19.0
  - **Homepage**: https://getartcraft.com/apps/filmcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.filmcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.gridcraft</strong> - Open-source, native spreadsheet that works the way Excel users expect</summary>

  - **Version**: 0.18.0
  - **Homepage**: https://getartcraft.com/apps/gridcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.gridcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.lightcraft</strong> - Open-source, native photo library and raw developer that works the way</summary>

  - **Version**: 0.20.0
  - **Homepage**: https://getartcraft.com/apps/lightcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.lightcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.pdfcraft</strong> - Open-source, native PDF workbench: read, comment, fill and sign forms,</summary>

  - **Version**: 0.20.0
  - **Homepage**: https://getartcraft.com/apps/pdfcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.pdfcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.photocraft</strong> - Open-source, native image editor with familiar, professional tools</summary>

  - **Version**: 0.22.0
  - **Homepage**: https://getartcraft.com/apps/photocraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.photocraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.soundcraft</strong> - Open-source, native digital audio workstation</summary>

  - **Version**: 0.19.0
  - **Homepage**: https://getartcraft.com/apps/soundcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.soundcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.vectorcraft</strong> - Open-source, native vector illustration app</summary>

  - **Version**: 0.23.0
  - **Homepage**: https://getartcraft.com/apps/vectorcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.vectorcraft.out -c [...]`
</details>
<details>
  <summary><strong>artcraft.wordcraft</strong> - Open-source, native word processor that works the way Word users expect</summary>

  - **Version**: 0.17.0
  - **Homepage**: https://getartcraft.com/apps/wordcraft
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#artcraft.wordcraft.out -c [...]`
</details>
<details>
  <summary><strong>editors.concat</strong> - Free and open source video editor</summary>

  - **Version**: 0.2.9
  - **Homepage**: https://github.com/jub0t/Concat
  - **License**: AGPL-3.0-or-later
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#editors.concat.out -c [...]`
</details>
<details>
  <summary><strong>noctalia.shell</strong> - A sleek, customizable desktop shell crafted for Wayland</summary>

  - **Version**: 5.4.1
  - **Homepage**: https://github.com/noctalia-dev/noctalia
  - **License**: MIT
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#noctalia.shell.out -c [...]`
</details>
<details>
  <summary><strong>noctalia.umbriel</strong> - A Wayland compositor built on wlroots</summary>

  - **Version**: 0.1.0
  - **Homepage**: https://github.com/noctalia-dev/umbriel
  - **License**: MIT
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#noctalia.umbriel.out -c [...]`
</details>
<details>
  <summary><strong>noctalia.xdg-desktop-portal-umbriel</strong> - xdg-desktop-portal backend for the Umbriel compositor</summary>

  - **Version**: 0.1.0
  - **License**: MIT
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix shell github:fmway/inputs#noctalia.xdg-desktop-portal-umbriel.out -c [...]`
</details>

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
