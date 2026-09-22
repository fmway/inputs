#!/bin/env bash
# Publish data/: minify the refined trees, upload them to the GitHub release
# tagged `data-yyyymmdd`, and refresh dev/data-lock.json with the tag plus the
# SRI hash of each <input>-<system>.min.json (computed locally before upload,
# so the hash the main flake pins always matches the remote asset).
#
# The daily release is overwritten in place (delete + recreate) because the
# pipeline can run several times a day; the tag name and asset URLs stay stable
# within a day, only their content moves forward.
#
# Run after `nix run ./dev#refresh`; needs cwd = repo root and a `gh` session.
# Exits non-zero when any collected system has no refined data (e.g. refresh
# hasn't run yet).

set -eu

NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"
export NIX_CONFIG

command -v jq >/dev/null || { echo "publish.sh: jq is required (use \`nix run ./dev#publish\`)" >&2; exit 1; }
command -v gh >/dev/null || { echo "publish.sh: gh is required (use \`nix run ./dev#publish\`)" >&2; exit 1; }
command -v nix >/dev/null || { echo "publish.sh: nix is required (use \`nix run ./dev#publish\`)" >&2; exit 1; }

collection_dir="$PWD/dev/collections.json"
tag="data-$(date -u +%Y%m%d)"
repo="${GITHUB_REPOSITORY:-$(
  gh repo view --json nameWithOwner -q .nameWithOwner
)}"

echo "publishing data release: $tag ($repo)"

stag="$(mktemp -d)"
trap 'rm -rf "$stag"' EXIT HUP INT TERM

jq -r 'to_entries[] | [.value.inputName, (.value.systems | join(" "))] | @tsv' "$collection_dir" |
  while IFS=$'\t' read -r input systems; do
    for system in $systems; do
      json="data/$input/$system.json"
      [ -s "$json" ] || {
        echo "publish.sh: missing $json — run \`nix run ./dev#refresh\` first" >&2
        exit 1
      }

      min="data/$input/$system.min.json"
      jq -cS . "$json" >"$min"
      sha="$(nix hash file --type sha256 --sri "$min")"

      cp "$json" "$stag/$input-$system.json"
      cp "$min" "$stag/$input-$system.min.json"

      printf '  %s  %s-%s.min.json\n' "$sha" "$input" "$system"
      echo "$input-$system $sha" >>"$stag/.hashes"
    done
  done

# Recreate the release so re-runs within one day overwrite it in place.
gh release delete "$tag" --yes --cleanup-tag 2>/dev/null || true
gh release create "$tag" "$stag"/* --title "$tag" --notes "automated data release for fmway/inputs" >/dev/null

# Write the lock the main flake reads at eval time (tag + per-asset SRI).
sha_map='{}'
while read -r key sha; do
  sha_map="$(jq -nc --argjson m "$sha_map" --arg k "$key" --arg v "$sha" '$m + {($k): $v}')"
done <"$stag/.hashes"

jq -n --arg tag "$tag" --argjson sha "$sha_map" '{tag: $tag, sha256: $sha}' >dev/data-lock.json
