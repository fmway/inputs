# AGENTS.md

Implementation notes for AI agents and contributors working on this repo. The
consumer-facing documentation lives in [README.md](README.md).

## Layout

- `flake.nix` — generated (`nix run ./dev#flake flake.nix`), not hand-edited.
  Declares **no inputs** (never writes a lock); its `nixConfig` is derived from
  the collection's `extraCaches`; `outputs = inputs: import ./outputs.nix inputs`.
- `outputs.nix` — the real logic. Reads `dev/collections.json`, resolves the
  dev flake into real inputs via with-inputs (fetched over GitHub from the very
  pin in `dev/flake.lock`), and rebuilds every collected input's
  `packages.<system>` from refined data.
- `dev/flake.nix`, `dev/flake.lock` — every collected input's pin plus the
  tooling: `apps.<system>.refresh` (collect + refine), `apps.<system>.readme`
  (regenerates README from the collection), `apps.<system>.flake` (regenerates
  `flake.nix` from the `nixConfig`-building spec), and a
  `devShells.<system>.default`. Also exposes `inputs` and `collections` as
  outputs (the tooling and main flake read them).
- `dev/collections.json` — the collection: public output key →
  `{ inputName, repo, systems, extraCaches?, aliases?, tags? }`. Keep
  `inputName` in sync with `dev/flake.nix` inputs. This is the *private*
  source of truth (not a flake output).
- `data/<input>/<system>.json` — refined, committed. `data/**/*.jsonl` — raw
  scratch, gitignored.
- `lib/packages.nix` — rebuilds one `packages.<system>` attrset from a refined
  tree: cached leaf → fake derivation (`lib/mkFakeDerivation.nix`), uncached
  leaf → real upstream derivation plus `meta.warning`. Only the attribute you
  read is forced, so cached packages never evaluate the upstream flake.
- `dev/scripts/refresh.sh` — the update pipeline (collect + refine in one
  step).

## Output shape (main flake)

For every collection key the flake exposes a namespace attribute
`"owner/repo"` (and each `aliases` entry points at the same value):

```nix
{
  packages   = <rerouted packages.<system>, rebuilt from data>;
  outputs    = <raw upstream flake outputs>;   # touching these evaluates the upstream flake
  sourceInfo = <upstream source info>;
  extraCaches? = { substituters = [...]; trusted-public-keys = [...]; };
}
```

plus:

- `.inputs` — the resolved upstream input flakes (raw; e.g. `.#inputs.llm-agents`
  is the untouched upstream flake).
- `.packages.<system>."owner/repo".<pkg>` — the system-first orientation,
  sharing the same thunks.

Reading `.packages` never forces the upstream outputs — cached leaves stay
~0.1 s. Only `.outputs`, uncached leaves, and `.orig` touch the upstream flake
(`.outputs` also needs the `nixpkgs-lib.follows` alias below to evaluate).

## Resolution mechanics

- The main flake declares **no inputs**. `outputs.nix` locates the `with-inputs`
  node in `dev/flake.lock`, fetches that exact commit from GitHub with
  `builtins.fetchTarball`, then calls
  `(import with-inputs).from.flake ./dev (_: { nixpkgs-lib.follows = "nixpkgs"; })`
  to get the resolved inputs, and applies `mkOutputs` over them. Do not vendor
  with-inputs.
- The `{}` argument is with-inputs' follows/override block. The
  `nixpkgs-lib.follows = "nixpkgs"` alias is **required**: with-inputs resolves
  each sub-input by name against the lock's top-level nodes, and flake-parts'
  `nixpkgs-lib` exists only as a follows edge (`llm-agents → nixpkgs`), so it
  has no node of its own — without the alias, evaluating the *upstream* flake
  (uncached packages, `.outputs`, `.orig`) fails with
  `attribute 'lib' missing`.

## Invariants — do not break

- `flake.nix` is **generated** — never edit it by hand. Change `outputs.nix`
  for logic or the `flake` spec in `dev/flake.nix` for metadata, then run
  `nix run ./dev#flake flake.nix`.
- `data/**/*.json` must stay **git-tracked**, or the main flake won't see them
  (nix reads the working tree). After `refresh`, stage the new files.
- `systems` per collection entry is **manual** — when an upstream flake changes
  its `packages` platforms, update `dev/collections.json`; `refresh` prunes the
  stale `data` for systems no longer listed.
- `nix flake check` on the main flake **fails by design** («...is not a
  derivation», nested namespace under `packages.<system>`). Do not "fix" it;
  use the targeted evals below. (`nix flake check ./dev` passes; its
  omitted-systems warning is acceptable.)
- Fake derivations have no `.drv`; reading `.drvPath` throws on purpose. Reach
  the real derivation via `.orig`.

## Verifying changes

Run from the repo root:

```sh
# cached package via alias — must be ~0.1 s with no upstream fetch
nix eval --raw '.#llm-agents.packages.x86_64-linux.opencode.name'

# system-first orientation (same thunk)
nix eval --raw '.#"numtide/llm-agents.nix".opencode.name'

# uncached package — real derivation + warning
nix eval --json '.#llm-agents.apm' \
  --apply 'd: d.meta.warning or null'

# .orig reaches the real derivation
nix eval --raw '.#llm-agents.opencode.orig.drvPath'

# .outputs is the raw upstream shape (evaluates the upstream flake)
nix eval --json '.#llm-agents.outputs' --apply 'builtins.attrNames'

# dev tooling resolves
nix eval --json ./dev#refresh.program
nix eval --json ./dev#readme.program
nix eval --json ./dev#flake.program
```

There is no test suite (`tests/` is empty) — these targeted evals are the
verification.

## Update pipeline

`refresh.sh` runs two phases back to back (raw snapshots are kept as
gitignored `.jsonl` scratch); **cwd must be the repo root**. Systems are read
from `dev/collections.json` — no discovery. Env overrides: `WORKERS`
(default 8), `NIX_EVAL_JOBS`.

1. **Collect** — for each key in `dev/collections.json`: resolves the input
   name and `systems` from the entry, prunes any previously collected
   `data/<input>/<system>.json{,l}` not listed in `systems`, then runs
   `nix-eval-jobs --check-cache-status --flake ./dev#inputs.<name>.packages.<system>`
   per system into `data/<name>/<system>.jsonl`. Exits non-zero if any system
   failed, so CI won't commit a moved lock without matching data.
2. **Refine** — folds the snapshots into nested committed trees
   (`data/<name>/<system>.json`): cached leaves keep `name/system/outputs/drvPath`,
   uncached (and errored) leaves become `{ isCached = false }`.

Afterwards regenerate the derived files:

```sh
nix run ./dev#readme README.md
nix run ./dev#flake flake.nix
```

`readme` regenerates the "Current flakes" section from `dev/collections.json`
via `fmway-lib`'s `mkParse'` (template markers `<!--{% ... %}-->`); `flake`
regenerates the main `flake.nix` via `lib.fmway.genNix` on the `flake` spec in
`dev/flake.nix`.

CI (`.github/workflows/update.yml`) runs daily: bump tagged inputs → `nix flake
update` (only the collected input names) → `refresh` → `readme` → `flake` →
auto-commit. It also triggers on pushes touching `dev/collections.json` or
`dev/flake.nix` (and `workflow_dispatch`). `nixpkgs`, `with-inputs`, and
`fmway-lib` are never bumped by CI — move those pins manually when needed.

Inputs marked `"tags": true` are pinned to a release **tag** (e.g.
`github:moku-project/moku/v0.13.1`). Before locking, CI queries
`repos/<owner>/<repo>/releases/latest` and rewrites the tag in `dev/flake.nix`
to the newest release, so these inputs move forward without manual edits.

## Adding an input

1. Add `inputs.<name>.url` in `dev/flake.nix`; run `nix flake lock` in `./dev`.
2. Add the mapping in `dev/collections.json`:
   `"owner/repo" → { inputName = "<name>"; repo = "https://github.com/owner/repo"; systems = [ "<system>" ]; }`
   plus optional `aliases`, `extraCaches`, and `tags = true` for a
   release-tagged input (CI bumps the tag).
3. Run `nix run ./dev#refresh`, `nix run ./dev#readme README.md`, and
   `nix run ./dev#flake flake.nix`; commit `data/`, `dev/flake.lock`,
   `dev/collections.json`, `README.md`, and `flake.nix`.
