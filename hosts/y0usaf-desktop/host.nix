{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts = {
    packages = [flakeInputs.fonts.packages."${system}".default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-desktop";
  trustedUsers = ["y0usaf"];
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
  user = {
    hardware.controllers.enable = true; # hidraw udev rules (finix-safe namespace)
    programs.discord.stable.pinLegacy = true;
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
        # Disabled: y0usaf/game-mods repo deleted from GitHub (404).
        # fetchFromGitHub pin d54ec2df unfetchable. Re-enable after
        # repo restored or mods vendored elsewhere.
        enable = false;
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
    btrbk-snapshots = {
      enable = true;
      subvolumes = ["@dcim" "@music" "@persist"];
    };
    docker.enable = true;
    waydroid.enable = false;

    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-desktop";
    };
    nginx = {
      enable = true;
    };
  };

  # prime-agent build requires npm install with network (lockfile has
  # unresolvable packages not in npm registry like undici-types@7.16.0).
  nix.settings.sandbox = "relaxed";

  # TCP 25565 (minecraft host) moved 2026-07-30 to modules/core/firewall.nix,
  # the desktop's default firewall. `networking` is not on compat-import's
  # whitelist, so this line was inert from the finix switch onward
  # (DRIFT-AUDIT #1).
}
