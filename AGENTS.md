# AGENTS.md

Implementation notes for AI agents and contributors working on this repo. The
consumer-facing documentation lives in [README.md](README.md).

## Layout

- `flake.nix` — main flake (`inputs = {}`, never writes a lock). Reads
  `dev/flake.lock`, resolves it into flake-shaped inputs via with-inputs
  (fetched over GitHub from that very pin), and rebuilds every collected
  input's `packages.<system>` from refined data.
- `dev/flake.nix`, `dev/flake.lock` — every collected input's pin plus the
  tooling: `apps.<system>.refresh` (collect + refine) and
  `apps.<system>.readme` (regenerates README from the collection), and a
  `devShells.<system>.default`. Also exposes `inputs` and `collections` as
  outputs (the tooling and main flake read them).
- `dev/collections.json` — the collection: public output key →
  `{ inputName, repo, extraCaches?, aliases? }`. Keep `inputName` in sync with
  `dev/flake.nix` inputs. This is the *private* source of truth (not a flake
  output).
- `data/<input>/systems.nix` — systems an input actually provides, written by
  `refresh` from the upstream `packages` output and imported by `flake.nix`
  (no system list is maintained anywhere).
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
  outputs    = <upstream flake outputs, but `packages` replaced by the same
               rerouted packages thunk>;
  sourceInfo = <upstream source info>;
  extraCaches = { substituters = [...]; trusted-public-keys = [...]; };
}
```

plus:

- `.inputs` — the resolved upstream input flakes (raw; e.g. `.#inputs.llm-agents`
  is the untouched upstream flake).
- `.packages.<system>."owner/repo".<pkg>` — the system-first orientation,
  sharing the same thunks.

The shape is explicit (no `//` merge with upstream outputs), so reading
`.packages` never forces the upstream outputs — cached leaves stay ~0.1 s.
Only `.outputs`, uncached leaves, and `.orig` touch the upstream flake.

On the CLI, use an **alias**: `nix` resolves `#attr/with/slash` specially, so
`.#"numtide/llm-agents.nix"` never reaches these outputs reliably — use
`.#llm-agents`. In Nix expressions attribute access on the input works either
way.

## Resolution mechanics

- The main flake declares **no inputs**. `flake.nix` locates the `with-inputs`
  node in `dev/flake.lock`, fetches that exact commit from GitHub with
  `builtins.fetchTarball`, then calls
  `(import with-inputs).from.flake ./dev (_: { nixpkgs-lib.follows = "nixpkgs"; })`.
  Do not vendor with-inputs.
- The `{}` argument is with-inputs' follows/override block. The
  `nixpkgs-lib.follows = "nixpkgs"` alias is **required**: with-inputs resolves
  each sub-input by name against the lock's top-level nodes, and flake-parts'
  `nixpkgs-lib` exists only as a follows edge (`llm-agents → nixpkgs`), so it
  has no node of its own — without the alias, evaluating the *upstream* flake
  (uncached packages, `.outputs`, `.orig`) fails with
  `attribute 'lib' missing`.

## Invariants — do not break

- `data/**/*.json` and `data/<input>/systems.nix` must stay **git-tracked**,
  or the main flake won't see them (nix reads the working tree). After
  `refresh`, stage the new files.
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
nix eval --json '.#llm-agents.apm' --apply 'd: d.meta.warning or null'

# .orig reaches the real derivation
nix eval --raw '.#llm-agents.opencode.orig.drvPath'

# .outputs keep the upstream shape (packages = same rerouted thunk)
nix eval --json '.#llm-agents.outputs' --apply 'builtins.attrNames'

# dev tooling resolves
nix eval --json ./dev#refresh
nix eval --json ./dev#readme
```

## Update pipeline

`refresh.sh` runs two phases back to back (raw snapshots are kept as
gitignored `.jsonl` scratch); **cwd must be the repo root**:

1. **Collect** — for each key in `dev/collections.json`: resolves the input
   name against `(import ./dev/flake.nix).inputs`, discovers the actual
   systems from `./dev#inputs.<name>.packages` (writing
   `data/<name>/systems.nix`), prunes any previously collected system the
   flake no longer provides, then runs
   `nix-eval-jobs --check-cache-status --flake ./dev#inputs.<name>.packages.<system>`
   per system into `data/<name>/<system>.jsonl`. Exits non-zero if any system
   failed, so CI won't commit a moved lock without matching data.
2. **Refine** — folds the snapshots into nested committed trees
   (`data/<name>/<system>.json`): cached leaves keep `name/system/outputs/drvPath`,
   uncached (and errored) leaves become `{ isCached = false }`.

`nix run ./dev#readme README.md` afterwards regenerates the
"Current flakes" section from `dev/collections.json` via `fmway-lib`'s
`mkParse'` (template markers `<!--{% ... %}-->`).

CI (`.github/workflows/update.yml`) runs daily: `nix flake update` in `./dev`
→ `refresh` → `readme` → auto-commit. It also triggers on pushes touching
`dev/collections.json` or `dev/flake.nix` (and `workflow_dispatch`).

## Adding an input

1. Add `inputs.<name>.url` in `dev/flake.nix`; run `nix flake lock` in `./dev`.
2. Add the mapping in `dev/collections.json`:
   `"owner/repo" → { inputName = "<name>"; repo = "https://github.com/owner/repo"; aliases = [ "<alias>" ]; }`
   (plus `extraCaches` when the upstream publishes a substituter).
3. Run `nix run ./dev#.refresh` and `nix run ./dev#readme README.md`.
