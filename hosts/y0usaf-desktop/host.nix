{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts = {
    packages = [
      flakeInputs.fast-fonts.packages."${system}".default
    ];
    fontDir.enable = true;
  };
  hostname = "y0usaf-desktop";
  trustedUsers = ["y0usaf"];
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
  user = {
    programs.discord.stable.package =
      (import flakeInputs.nixpkgs-discord-legacy {
        inherit system;
        config.allowUnfree = true;
      }).discord;
    dev.work.linear-cli.settings = {
      workspace = "cook-unity";
    };
    gaming = {
      proton = {
        enable = true;
        nativeWayland = false;
        ntsync = true;
      };
      mangohud = {
        enable = true;
        enableSessionWide = true;
        refreshRate = 175;
      };
      bg3 = {
        enable = true;
        scriptExtender.enable = true;
        nativeModLoader.enable = true;
        wasd.enable = true;
        nativeCameraTweaks.enable = true;
      };
      runelite = {
        enable = true;
        scale = 2.0;
      };
    };
  };
  hardware = {
    bluetooth = {
      enable = true;
    };
    cpu.amd.enable = true;
    nvidia = {
      enable = true;
      management = {
        enable = true;
        maxClock = 2450;
        coreVoltageOffset = -100;
        memoryVoltageOffset = -100;
        fanCurve = [
          {
            temp = 50;
            speed = 0;
          }
          {
            temp = 75;
            speed = 50;
          }
          {
            temp = 90;
            speed = 70;
          }
        ];
      };
    };
    amdgpu.enable = false;
    display.outputs =
      (lib.genAttrs ["DP-1" "DP-2" "DP-3" "DP-4"] (_: {mode = "5120x1440@239.76";}))
      // {
        "eDP-1" = {
          mode = "1920x1080@300.00";
        };
      };
  };
  services = {
    btrbk-snapshots.enable = true;
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-desktop";
    };
    nginx = {
      enable = true;
    };
  };

  services.openssh.ports = [2222];
  networking.firewall.allowedTCPPorts = [25565 2222];
}
