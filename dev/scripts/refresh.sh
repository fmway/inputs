#!/bin/env bash
# Refresh data/: collect cache-status snapshots for every collected input,
# then fold them into the committed refined trees the main flake consumes.
#
# 1. Collect: evaluates each input flake's packages.<system> with
#    nix-eval-jobs --check-cache-status and writes one raw JSON-lines snapshot
#    per system to data/<input>/<system>.jsonl (gitignored scratch). Systems
#    the flake no longer provides are pruned. A failed system exits non-zero so
#    CI won't commit a moved lock without matching data.
#
# 2. Refine: folds the snapshots into nested trees
#    (data/<input>/<system>.json, committed). Cached leaves keep
#    name/system/outputs/drvPath; uncached (and errored) leaves become
#    { isCached = false }.
#
# Run with `nix run ./dev#refresh`; then commit the data/ and
# dev/flake.lock changes.

set -eu

NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"
export NIX_CONFIG
WORKERS="${WORKERS:-8}"
NIX_EVAL_JOBS="${NIX_EVAL_JOBS:-nix-eval-jobs}"
GCROOTS="$PWD/.gcroots"
mkdir -p "$GCROOTS"

command -v jq >/dev/null || { echo "refresh.sh: jq is required (use \`nix run ./dev#refresh\`)" >&2; exit 1; }
command -v "$NIX_EVAL_JOBS" >/dev/null || {
  echo "refresh.sh: $NIX_EVAL_JOBS is required (use \`nix run ./dev#refresh\`)" >&2
  exit 1
}

# Inputs are declared in ./dev/flake.nix and pinned in ./dev/flake.lock;
# metadata must be read from the dev flake, not the (empty) main flake.
# The collection is the main flake's *private* module file (never exposed as a
# flake output), so import it directly. Systems are NOT maintained anywhere:
# each input's systems are discovered dynamically from its own `packages`
# output, so a flake can gain (or lose) a system like armv7l-linux with no
# change here.
collection_dir="$PWD/dev/collections.json"
inputs="$(nix eval --json --impure --expr '(import ./dev/flake.nix).inputs')"

flakeref() {
  jq -r --arg k "$1" '.[$k].url' <<<"$inputs"
}

# Discover which systems a flake provides by evaluating its `packages` output
# and listing the attribute names. Nothing is hardcoded, so any system the
# flake offers (x86_64-linux, aarch64-linux, armv7l-linux, …) shows up here.
discover_systems() {
  input="$1"
  systems="$(nix eval "./dev#inputs.$input.packages" --apply 'builtins.attrNames' 2>/dev/null)"
  echo "$systems" > "./data/$input/systems.nix"
  nix eval --expr "$systems" --json | jq -r '.[]'
}

failed=0

keys_tmp="$(mktemp)"
trap 'rm -f "$keys_tmp"' EXIT HUP INT TERM
jq -r 'keys[]' "$collection_dir" >"$keys_tmp"

#### Collect
while IFS= read -r key; do
  input="$(jq -r --arg k "$key" '.[$k].inputName' "$collection_dir")"
  ref="$(flakeref "$input" || true)"
  [ -n "$ref" ] || continue

  echo "collecting $input ($key)"
  echo "  flake: $ref"
  mkdir -p "data/$input"

  systems="$(discover_systems "$input" | tr '\n' ' ')" || true
  if [ -z "${systems%% }" ]; then
      echo "  skip: no \`packages\` output upstream (attribute absent?)" >&2
      continue
  fi
  printf '  systems: %s\n' "$systems"

  # Prune any previously collected system the flake no longer provides
  # (including stale placeholder jsons for systems that are now absent).
  for old in data/"$input"/*.jsonl data/"$input"/*.json; do
    [ -e "$old" ] || continue
    s="$(basename "$old" .jsonl)"
    s="$(basename "$s" .json)"
    case " $systems " in
      *" $s "*) ;;
      *)
        rm -f -- "$old"
        echo "  pruned: $s (no longer provided upstream)" >&2
        ;;
    esac
  done

  for system in $systems; do
    out="data/$input/$system.jsonl"
    tmp="$out.tmp"
    errs="$GCROOTS/refresh.err"

    echo "  evaluating packages.$system"
    if "$NIX_EVAL_JOBS" \
      --workers "$WORKERS" \
      --gc-roots-dir "$GCROOTS" \
      --flake "./dev#inputs.$input.packages.$system" \
      --check-cache-status \
      --option accept-flake-config true \
      >"$tmp" 2>"$errs"; then
      # nix-eval-jobs can report warnings but still exit 0; an empty snapshot
      # usually means the attribute does not exist upstream.
      if [ -s "$tmp" ]; then
        mv "$tmp" "$out"
        echo "    ok: $(wc -l <"$out") records"
      else
        rm -f "$tmp"
        echo "    skip: packages.$system produced no records (attribute absent upstream?)" >&2
      fi
    elif grep -q "does not provide attribute 'packages.$system'" "$errs"; then
      rm -f "$tmp"
      echo "    skip: packages.$system does not exist upstream (keeping previous data)" >&2
    else
      rm -f "$tmp"
      echo "    FAILED: packages.$system" >&2
      sed -n '1,3p' "$errs" >&2
      failed=1
    fi
  done
done <"$keys_tmp"

#### Refine
# Newer nix-eval-jobs reports cacheStatus ("cached" | "local" | "notBuilt");
# older ones report isCached (bool). A path that is present locally or in a
# substituter is usable, so either of those counts as cached.
refine_leaves='
  reduce .[] as $r ({};
    if $r.error then
      setpath($r.attrPath; { isCached: false })
    else
      setpath($r.attrPath; {
        isCached: ($r.cacheStatus == "cached" or $r.cacheStatus == "local" or $r.isCached == true),
        name: $r.name,
        system: $r.system,
        outputs: ($r.outputs // {}),
        drvPath: $r.drvPath
      })
    end)'

jq -r 'keys[]' "$collection_dir" | while IFS= read -r key; do
  input="$(jq -r --arg k "$key" '.[$k].inputName' "$collection_dir")"
  for jsonl in data/"$input"/*.jsonl; do
    [ -e "$jsonl" ] || continue
    system="$(basename "$jsonl" .jsonl)"
    out="data/$input/$system.json"
    if [ -s "$jsonl" ]; then
      tmp="$out.tmp"
      jq -s -S "$refine_leaves" "$jsonl" >"$tmp"
      mv "$tmp" "$out"
      cached="$(jq -r '.. | objects | select(has("isCached")) | .isCached' "$out" | sort | uniq -c | tr '\n' ' ')"
      echo "refined $input/$system: $cached"
    fi
  done
done

exit "$failed"
