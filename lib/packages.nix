# Rebuilds a packages.<system> attrset for one collected flake input.
#
# Every leaf in `dataFile` came from `nix-eval-jobs --check-cache-status` and
# was refined by scripts/refresh.sh:
#
#   * isCached == true  -> a fake derivation: outPath (and any other outputs)
#     are the recorded store paths, so `nix build` substitutes them directly
#     without evaluating the upstream flake. The real upstream derivation is
#     kept under `.orig` and only forced if the consumer actually touches it.
#   * isCached == false -> the real upstream derivation, rebuilt from source —
#     marked with a `meta.warning` so it is clear no cache is available.
#
# Reading one attribute forces exactly that branch of the data and, for a
# cached leaf, never forces the upstream flake.
{
  system,
  dataFile,
  original,
}:
let
  notCachedWarning = "no cached binary available — this package must be built locally from source";

  data =
    if builtins.pathExists dataFile then
      builtins.fromJSON (builtins.readFile dataFile)
    else
      { };

  atPath =
    path:
    builtins.foldl' (acc: key: acc.${key}) original path;

  realFor =
    path:
    let
      drv = atPath path;
    in
    drv // {
      meta = (drv.meta or { }) // {
        warning = notCachedWarning;
      };
    };

  fakeFor =
    path: entry:
    import ./mkFakeDerivation.nix {
      inherit path entry;
      value = atPath path;
    };

  project =
    path:
    builtins.mapAttrs (name: value:
      if value ? isCached then
        let
          path' = path ++ [ name ];
        in
        if value.isCached then fakeFor path' value else realFor path'
      else
        project (path ++ [ name ]) value);
in
project [ ] data