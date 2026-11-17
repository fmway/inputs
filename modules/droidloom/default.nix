# TODO: slops, need to reverify

flake:
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.droidloom;
  system = pkgs.stdenv.hostPlatform.system;
  defaultPackage = flake.packages.${system}.droidloom;
  droidloomSetup = pkgs.writeShellApplication {
    name = "droidloom-setup";
    runtimeInputs = with pkgs; [
      curl
      zstd
      gnutar
      coreutils
      jq
    ];
    text = pkgs.replaceVars ./droidloom-setup.sh {
      inherit (cfg.package) version;
    };
  };
in {
  options.virtualisation.droidloom = {
    enable = lib.mkEnableOption "Droidloom, Android applications in native Wayland windows";

    hostUid = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1000;
      description = "Host UID of the desktop user Android renders for.";
    };

    hostGid = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1000;
      description = "Host GID of the desktop user Android renders for.";
    };

    renderNode = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/renderD128";
      description = "DRM render node Android uses for GPU rendering.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "inputs.virtualisation.packages.<system>.droidloom";
      description = "The Droidloom host package built by this flake.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      droidloomSetup
    ];

    systemd.globalEnvironment = {
      DROIDLOOM_HOST_PEER_PID = "0";
      DROIDLOOM_HOST_PEER_UID = toString cfg.hostUid;
      DROIDLOOM_HOST_PEER_GID = toString cfg.hostGid;
      DROIDLOOM_RENDER_NODE = cfg.renderNode;
      DROIDLOOM_MODE = "desktop";
    };

    systemd.services.droidloomd = {
      description = "Droidloom Android cell lifecycle daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/droidloomd";
        TimeoutStopSec = "20s";
        KillMode = "mixed";
        OOMPolicy = "continue";
        Restart = "on-failure";
        RestartSec = "1s";
        RuntimeDirectory = "droidloom";
        RuntimeDirectoryMode = "0755";
      };
    };

    systemd.user.services.droidloom = {
      description = "Droidloom Android application runtime";
      after = [
        "graphical-session-pre.target"
        "droidloom-audio.socket"
        "droidloom-gpu.socket"
        "droidloom-devices.socket"
      ];
      wants = [
        "droidloom-applications.service"
        "droidloom-audio.socket"
        "droidloom-gpu.socket"
        "droidloom-devices.socket"
        "droidloom-recovery.service"
      ];
      partOf = [ "graphical-session.target" ];
      unitConfig.ConditionPathExists = "/etc/droidloom/cell.json";
      serviceConfig = {
        Type = "notify";
        NotifyAccess = "main";
        EnvironmentFile = "-%t/droidloom/session.env";
        ExecStartPre = "${pkgs.systemd}/bin/systemctl start droidloomd.service";
        ExecStart = "${cfg.package}/bin/droidloom-wayland";
        ExecStartPost = "${cfg.package}/bin/droidloomctl start --cell";
        ExecStopPost = "${pkgs.systemd}/bin/systemctl stop droidloomd.service";
        Restart = "on-failure";
        RestartSec = "1";
        TimeoutStartSec = "150s";
        TimeoutStopSec = "150s";
      };
    };

    systemd.user.services.droidloom-applications = {
      description = "Droidloom native application catalog and theme";
      partOf = [ "droidloom.service" ];
      after = [ "droidloom.service" ];
      unitConfig.ConditionPathExists = "/etc/droidloom/cell.json";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/droidloom-applications";
        Restart = "on-failure";
        RestartSec = "2";
      };
    };

    systemd.user.services.droidloom-recovery = {
      description = "Droidloom Android cell crash recovery";
      partOf = [ "droidloom.service" ];
      after = [ "droidloom.service" ];
      bindsTo = [ "droidloom.service" ];
      unitConfig = {
        ConditionPathExists = "/etc/droidloom/cell.json";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.systemd}/bin/systemctl start droidloomd.service";
        ExecStart = "${cfg.package}/bin/droidloomctl supervise --cell";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "150s";
        TimeoutStopSec = "10s";
      };
    };

    systemd.user.services.droidloom-audio = {
      description = "Droidloom host audio broker";
      after = [ "pipewire.socket" ];
      wants = [ "pipewire.socket" ];
      partOf = [ "droidloom.service" ];
      requires = [ "droidloom-audio.socket" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/droidloom-audio --socket %t/droidloom/audio.sock";
        EnvironmentFile = "-%h/.config/droidloom/audio.env";
        Restart = "on-failure";
        RestartSec = "1";
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };

    systemd.user.sockets.droidloom-audio = {
      description = "Droidloom private Android audio endpoint";
      partOf = [ "droidloom.service" ];
      socketConfig = {
        ListenSequentialPacket = "%t/droidloom/audio.sock";
        SocketMode = "0666";
        DirectoryMode = "0700";
        RemoveOnStop = true;
      };
    };

    systemd.user.services.droidloom-gpu = {
      description = "Droidloom GPU server: Android Vulkan on the host driver";
      partOf = [ "droidloom.service" ];
      requires = [ "droidloom-gpu.socket" ];
      serviceConfig = {
        EnvironmentFile = "-/etc/droidloom/runtime.env";
        ExecStart = "${cfg.package}/bin/droidloom-gpu-server";
        Restart = "on-failure";
        RestartSec = "1";
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };

    systemd.user.sockets.droidloom-gpu = {
      description = "Droidloom GPU forwarding endpoint";
      partOf = [ "droidloom.service" ];
      socketConfig = {
        ListenStream = "%t/droidloom/gpu.sock";
        SocketMode = "0666";
        DirectoryMode = "0700";
        RemoveOnStop = true;
      };
    };

    systemd.user.services.droidloom-devices = {
      description = "Droidloom host haptics, camera and fingerprint broker";
      partOf = [ "droidloom.service" ];
      requires = [ "droidloom-devices.socket" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/droidloom-devices";
        Restart = "on-failure";
        RestartSec = "1";
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
      };
    };

    systemd.user.sockets.droidloom-devices = {
      description = "Droidloom private Android haptics, camera, fingerprint and credential endpoints";
      partOf = [ "droidloom.service" ];
      socketConfig = {
        ListenSequentialPacket = [
          "%t/droidloom/haptics.sock"
          "%t/droidloom/camera.sock"
          "%t/droidloom/fingerprint.sock"
          "%t/droidloom/credential.sock"
        ];
        SocketMode = "0666";
        DirectoryMode = "0700";
        RemoveOnStop = true;
      };
    };
  };
}
