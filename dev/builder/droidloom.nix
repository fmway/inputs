{ lib
, stdenv
, craneLib
, pkg-config
, glslang
, autoPatchelfHook
, pipewire
, wayland
, libdrm
, libgbm
, libxkbcommon
, linux-pam
, vulkan-loader
, source
, ...
}: let
  pname = "droidloom";
  version = let v = builtins.fromJSON (builtins.readFile "${source}/packaging/arch/version.json"); in "${v.version}-${toString v.release}";

  hostPackages = [
    "droidloom-supervisor"
    "droidloom-wayland"
    "droidloom-applications"
    "droidloom-audio"
    "droidloom-gpu-server"
    "droidloom-devices"
    "droidloom-doctor"
    "droidloom-package-support"
  ];
  cargoExtraArgs = "--locked ${lib.concatStringsSep " " (map (p: "-p ${p}") hostPackages)}";

  cargoVendorDir = craneLib.vendorCargoDeps {
    src = craneLib.cleanCargoSource source;
  };

  commonArgs = {
    inherit pname version cargoVendorDir cargoExtraArgs;

    src = source;

    strictDeps = true;
    doCheck = false;

    nativeBuildInputs = [
      autoPatchelfHook
      pkg-config
      glslang
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      pipewire
      wayland
      libdrm
      libgbm
      libxkbcommon
    ];

    runtimeDependencies = [
      pipewire
      wayland
      libdrm
      libgbm
      libxkbcommon
      vulkan-loader
      linux-pam
    ];

    postInstall = ''
      mkdir -p $out/lib/droidloom $out/share/droidloom $out/share/polkit-1/actions
      mv $out/bin/droidloom-package-helper $out/lib/droidloom/droidloom-package-helper
      chmod 755 $out/lib/droidloom/droidloom-package-helper
      cp ${source}/packaging/arch/org.droidloom.setup.policy $out/share/polkit-1/actions/org.droidloom.setup.policy
      substituteInPlace $out/share/polkit-1/actions/org.droidloom.setup.policy \
        --replace-warn "/usr/lib/droidloom/droidloom-package-helper" "$out/usr/lib/droidloom/droidloom-package-helper"
    '';

    meta = {
      description = "Android applications in native Wayland windows";
      homepage = "https://github.com/denialwm/droidloom";
      license = lib.licenses.gpl3Plus;
      mainProgram = "droidloomctl";
      platforms = [ "x86_64-linux" ];
    };
  };

  depsArgs = removeAttrs commonArgs [ "postInstall" "meta" ];
in craneLib.buildPackage (commonArgs // {
  cargoArtifacts = craneLib.buildDepsOnly depsArgs;
})
