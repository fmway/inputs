{ lib
, stdenv
, rustPlatform
, desktop-file-utils
, pkg-config
, alsa-lib
, autoPatchelfHook
, dbus
, libGL
, vulkan-loader
, wayland
, libxkbcommon
, libx11
, libxcb
, libxcursor
, libxi
, libxrandr
, fontconfig
, freetype
, appstream
, source
, name
, buildFeatures ? []
, craft-fonts ? (if builtins.pathExists "${source}/packaging/fonts.sh" then fetchTree {
    repo = "craft-fonts";
    owner= "storytold";
    type = "github";
    rev = builtins.head (builtins.match ".*local revision=([^\n]+).*" (builtins.readFile "${source}/packaging/fonts.sh"));
  } else null)
, buildDate ? (let
    e = start: range: builtins.substring start range source.lastModifiedDate;
  in "${e 0 4}-${e 4 2}-${e 6 2}")
, pkgs
, ...
}:
let
  importYaml = file: builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommandNoCC "converted-yaml.json" {
        nativeBuildInputs = [ pkgs.yj ];
      } ''
        yj < "${file}" > "$out"
      ''
    )
  );
  pname = name;
  appId = "ai.storyteller.${name}";

  version = (fromTOML (builtins.readFile "${source}/Cargo.toml")).workspace.package.version;
  script = builtins.readFile "${source}/packaging/linux/package.sh";
  buildScript = lib.removeSuffix ")" (builtins.head (builtins.match ".*(cargo build --release [^\n]*).*" script));
  buildFlags = let
    r = builtins.split "(-p|--package) ([^\t ]+)" buildScript;
  in builtins.concatMap (x: if builtins.isList x then x else []) r;
  defaultBuildFeatures = let
    r = builtins.split "(-f|--features) ([^\t ]+)" buildScript;
  in builtins.concatMap (x: if builtins.isList x then lib.splitString "," (builtins.elemAt x 1) else []) r;
  meta = importYaml "${source}/packaging/linux/nfpm.yaml";
in rustPlatform.buildRustPackage {
  inherit pname version;

  buildFeatures = if buildFeatures == [] then defaultBuildFeatures else buildFeatures;

  src = source;
  cargoLock.lockFile = "${source}/Cargo.lock";
  cargoLock.allowBuiltinFetchGit = true;

  cargoBuildFlags = [ "--locked" ] ++ buildFlags;
  strictDeps = true;
  doCheck = false;

  nativeBuildInputs = [
    autoPatchelfHook
    pkg-config
    desktop-file-utils
    appstream
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    fontconfig
    freetype
    dbus
    libGL
    vulkan-loader
    wayland
    libxkbcommon
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
  ];

  runtimeDependencies = [
    dbus.lib
    libGL
    vulkan-loader
    wayland
    libxkbcommon
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
  ];

  postInstall = ''
    install -Dm644 $src/packaging/linux/${appId}.desktop \
      $out/share/applications/${appId}.desktop
    install -Dm644 $src/packaging/linux/${appId}.mime.xml \
      $out/share/mime/packages/${appId}.xml
    install -Dm644 $src/packaging/linux/${appId}.metainfo.xml.in \
      $out/share/metainfo/${appId}.metainfo.xml

    substituteInPlace $out/share/metainfo/${appId}.metainfo.xml \
      --replace-fail "@VERSION@" "${version}" \
      --replace-fail "@DATE@" "${buildDate}"
    substituteInPlace $out/share/applications/${appId}.desktop \
      --replace-fail "Exec=$pname" "Exec=$out/bin/$pname"

    desktop-file-validate $out/share/applications/${appId}.desktop
    XDG_CACHE_HOME=$TMPDIR/.cache appstreamcli validate --no-net \
      $out/share/metainfo/${appId}.metainfo.xml

    cp -R $src/assets/app-icon/hicolor $out/share/icons/hicolor

    for f in README.md LICENSE LICENSE-MIT LICENSE-APACHE COPYRIGHT NOTICE; do
      [ ! -f "$src/$f" ] || install -Dm644 "$src/$f" "$out/share/doc/$pname/$f"
    done

    ${lib.optionalString (!isNull craft-fonts) /* sh */ ''
      for f in ${craft-fonts}/fonts/*/OFL.txt; do
        [ -f "$f" ] || continue
        family="$(basename "$(dirname "$f")")"
        install -Dm644 "$f" "$out/share/doc/$pname/OFL-$family.txt"
      done
    ''}
  '';

  meta = {
    inherit (meta) description homepage;
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = name;
  };
}
