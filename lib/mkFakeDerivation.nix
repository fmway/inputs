# Builds one fake derivation from one refined data leaf.
#
# A fake derivation "walks and quacks" like a real derivation, but its
# store outputs are the paths recorded at collect time, given real store
# context via `builtins.appendContext`. `nix build` therefore treats them
# as genuine, already-built store paths and just substitutes them — no
# upstream flake evaluation, no nixpkgs closure piling up in the consumer.
#
#     value   the real upstream derivation (kept as `.orig`, forced on demand)
#     path    the attribute path of this package (for error messages)
#     entry   one refined data leaf:
#               { isCached = true; name; system; outputs = { out = "..."; ... } }
{
  value,
  path,
  entry,
}:
let
  outputs =
    entry.outputs or (throw "mkFakeDerivation: no outputs for ${builtins.concatStringsSep "." path}");
  outputNames = builtins.attrNames outputs;

  defaultOutput =
    if outputs ? bin then
      "bin"
    else if outputs ? out then
      "out"
    else if outputs ? lib then
      "lib"
    else if outputs ? dev then
      "dev"
    else
      builtins.head outputNames;

  # Bare store-path strings from the JSON snapshot need real context before
  # Nix will substitute them.
  withContext =
    p:
    builtins.appendContext p {
      ${p} = {
        path = true;
      };
    };

  outputsSet = builtins.listToAttrs (
    map (o: {
      name = o;
      value = withContext outputs.${o};
    }) outputNames
  );

  attrPath = builtins.concatStringsSep "." path;
  drvName = entry.name or "unnamed";
in
{
  type = "derivation";
  name = drvName;
  pname = (builtins.parseDrvName drvName).name;
  version = (builtins.parseDrvName drvName).version or entry.version or null;
  system = entry.system or null;
  meta = { };
  outputs = outputNames;
  outputName = defaultOutput;
  outPath = outputsSet.${defaultOutput};

  # There is no real .drv behind a fake derivation — it only serves
  # already-built outputs. The real derivation lives under `.orig`.
  drvPath = throw ''
    ${attrPath} is a fake derivation and has no .drv of its own. Build one of
    its recorded outputs instead (${builtins.concatStringsSep " " outputNames}),
    or reach the real upstream derivation via ${attrPath}.orig
  '';

  orig = value;
}
// outputsSet