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
- [nix-community/lanzaboote](https://github.com/nix-community/lanzaboote) (alias: lanzaboote)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) (alias: llm-agents)
<!--{% end %}-->

<!--{% markdowns.custom-namespace-section %}-->
### Custom namespaces
<details>
  <summary>agents.maki</summary>

  - **Supported Systems**: x86_64-linux, aarch64-linux, aarch64-darwin
  - **Usage**: `nix run github:fmway/inputs#agents.maki -- [...]`
</details>
<details>
  <summary>artcraft.cadcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/cadcraft
  - **Description**: Open-source computer-aided design and drafting: draft, dimension and plot 2D
drawings with a familiar command line, object snaps, layers, dimensions, hatches
and blocks. Opens and saves DXF and DWG; exports SVG and PNG.
Includes cadcraft-cli, a headless converter and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.cadcraft -- [...]`
</details>
<details>
  <summary>artcraft.deckcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/deckcraft
  - **Description**: Open-source, native presentation app that works the way PowerPoint users
expect. Themes, layouts, shapes, pictures, tables, charts, transitions and
animations; opens and saves PowerPoint (.pptx) files; full-screen slide show
with presenter view; GPU rendering (wgpu).
Includes deckcraft-cli, a headless renderer and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.deckcraft -- [...]`
</details>
<details>
  <summary>artcraft.designcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/designcraft
  - **Description**: Open-source, native page layout and publishing that works the way InDesign users expect.
Spreads and parent pages, threaded text frames, paragraph and character styles, swatches,
text wrap and a Knuth-Plass paragraph composer; IDML import and export.
Includes designcraft-cli, a headless renderer and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.designcraft -- [...]`
</details>
<details>
  <summary>artcraft.effectcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/effectcraft
  - **Description**: Open-source motion graphics and visual effects compositor.
Layers with keyframes and a graph editor, masks and shapes, text animators,
expressions, 3D cameras and lights, over 300 effects and a render queue
(H.264, HEVC, AV1, ProRes, WebM, image sequences); GPU compositing (wgpu).
Includes effectcraft-cli, a headless renderer, command runner and MCP server.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.effectcraft -- [...]`
</details>
<details>
  <summary>artcraft.figcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/figcraft
  - **Description**: Open-source, native interface design and prototyping tool.
Frames, vector shapes and text on an infinite canvas; auto layout and
constraints; components, variants, styles and variables; interactive
prototypes with a presentation mode; SVG and PNG export; GPU rendering (wgpu).
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.figcraft -- [...]`
</details>
<details>
  <summary>artcraft.filmcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/filmcraft
  - **Description**: Open-source, native video editor: edit video, color and sound.
Timeline editing with source and program monitors, color grading and scopes,
effects and keyframes, titles and captions, audio mixing with loudness meters,
and export; GPU compositing (wgpu).
Includes filmcraft-cli, a headless command runner, MCP server and exporter.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.filmcraft -- [...]`
</details>
<details>
  <summary>artcraft.gridcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/gridcraft
  - **Description**: Open-source, native spreadsheet that works the way Excel users expect.
Opens and saves .xlsx workbooks and CSV/TSV files; hundreds of worksheet
functions; formatting, sorting, filtering and charts.
Includes gridcraft-cli, a headless evaluator, converter and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.gridcraft -- [...]`
</details>
<details>
  <summary>artcraft.lightcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/lightcraft
  - **Description**: Open-source, native photo library and raw developer that works the way
Lightroom users expect. Import, rate, keyword and organise photos; develop
raw files non-destructively with exposure, tone, color grading, masks and
presets; GPU processing (wgpu). Includes lightcraft-cli, a headless renderer
and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.lightcraft -- [...]`
</details>
<details>
  <summary>artcraft.pdfcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/pdfcraft
  - **Description**: Open-source, native PDF workbench: read, comment, fill and sign forms,
organize, combine, split, edit, redact, protect and export PDFs.
Includes pdfcraft-cli, a headless command runner and opt-in MCP server.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.pdfcraft -- [...]`
</details>
<details>
  <summary>artcraft.photocraft</summary>

  - **Homepage**: https://getartcraft.com/apps/photocraft
  - **Description**: Open-source, native image editor with familiar, professional tools.
Layers, masks, adjustment layers, layer styles, type and brushes; opens and
saves layered PSD/PSB files; 8/16/32-bit documents; GPU compositing (wgpu).
Includes photocraft-cli, a headless converter and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.photocraft -- [...]`
</details>
<details>
  <summary>artcraft.soundcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/soundcraft
  - **Description**: Open-source, native digital audio workstation. Record, edit and mix
multitrack audio and MIDI in Edit and Mix windows; built-in EQ, dynamics,
reverb, delay and instruments; imports WAV, AIFF, FLAC, MP3 and MIDI.
Includes soundcraft-cli, a headless editor, bounce tool and MCP server.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.soundcraft -- [...]`
</details>
<details>
  <summary>artcraft.vectorcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/vectorcraft
  - **Description**: Open-source, native vector illustration app.
Pen, shape and brush tools, artboards, type, gradients, symbols and live
effects; opens and saves SVG and PDF.
Includes vectorcraft-cli, a headless converter and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.vectorcraft -- [...]`
</details>
<details>
  <summary>artcraft.wordcraft</summary>

  - **Homepage**: https://getartcraft.com/apps/wordcraft
  - **Description**: Open-source, native word processor that works the way Word users expect.
The ribbon, styles, tables, track changes, references and mail merge; reads
and writes .docx, opens .odt, .rtf, .html, .md and .txt, and exports PDF.
Includes wordcraft-cli, a headless converter and command runner.
  - **License**: MIT, Apache-2.0
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#artcraft.wordcraft -- [...]`
</details>
<details>
  <summary>editors.concat</summary>

  - **Homepage**: https://github.com/jub0t/Concat
  - **Description**: Free and open source video editor
  - **License**: AGPL-3.0-or-later
  - **Supported Systems**: x86_64-linux, aarch64-linux
  - **Usage**: `nix run github:fmway/inputs#editors.concat -- [...]`
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
