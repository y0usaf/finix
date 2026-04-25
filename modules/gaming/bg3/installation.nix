{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkMerge;
  inherit (config.user) gaming;

  mods = gaming.mods.bg3;
  cfg = gaming.bg3;

  bg3Bin = "${"${lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path}/steamapps/common/Baldurs Gate 3"}/bin";
  nativeModsDir = "${bg3Bin}/NativeMods";

  modSrc = "${mods.game-mods}/bg3";
  tomlFormat = pkgs.formats.toml {};

  cameraTweaks = cfg.nativeCameraTweaks;

  bg3seVersion = mods.bg3se.version;
in {
  options.user.gaming.bg3 = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Baldur's Gate 3 mod management";
    };

    scriptExtender.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install BG3 Script Extender (DWrite.dll auto-updater)";
    };

    nativeModLoader.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Install NativeModLoader (bink2w64.dll proxy).
        Required for WASD and NativeCameraTweaks.
        Back up the original bin/bink2w64.dll to bin/bink2w64_original.dll before enabling.
      '';
    };

    wasd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install WASD character movement mod";
      };
      settings = mkOption {
        inherit (tomlFormat) type;
        default = {
          ModHotkeys = {
            ToggleMovementMode = "key:capslock";
            HoldMovementMode = "";
            ToggleWalkspeed = "key:insert";
            HoldWalkspeed = "";
            ReloadConfig = "key:f11";
            ToggleAutoforward = "shift+key:w";
          };
          Core = {
            WalkSpeed = 0.3;
            WalkingIsDefault = false;
            SwitchToWalkingAfterCombat = false;
          };
          AutoToggleMovementMode = {
            EnableAutoTogglingMovementMode = true;
          };
          Mouselook = {
            EnableMouselook = true;
            EnableRotatePlusLeftclickMovesForward = true;
            RotateThreshold = 200;
          };
          InteractMoveBlocker = {
            BlockInteractMove = false;
          };
        };
        description = "BG3WASD TOML configuration settings";
      };
    };

    nativeCameraTweaks = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Native Camera Tweaks mod";
      };
      settings = mkOption {
        inherit (tomlFormat) type;
        default = {};
        description = "BG3NativeCameraTweaks TOML configuration settings";
      };
    };
  };

  config = mkIf cfg.enable {
    bayt.users."${config.user.name}".files = mkMerge [
      (mkIf cfg.scriptExtender.enable {
        "${bg3Bin}/DWrite.dll" = {
          source = "${pkgs.fetchzip {
            url = "https://github.com/Norbyte/bg3se/releases/download/${bg3seVersion}/BG3SE-Updater-${lib.removePrefix "updater-" bg3seVersion}.zip";
            sha256 = "sha256-XhintUwpaQ9AhWjsPvWMFLKF2D7WdjmhPcvNLoVtGho=";
            stripRoot = false;
          }}/DWrite.dll";
        };
      })

      (mkIf cfg.nativeModLoader.enable {
        "${bg3Bin}/bink2w64.dll" = {
          source = "${modSrc}/bin/bink2w64.dll";
        };
      })

      (mkIf cfg.wasd.enable {
        "${nativeModsDir}/BG3WASD.dll" = {
          source = "${modSrc}/bin/NativeMods/BG3WASD.dll";
        };
        "${nativeModsDir}/BG3WASD.toml" = {
          source = tomlFormat.generate "BG3WASD.toml" cfg.wasd.settings;
        };
      })

      (mkIf cameraTweaks.enable {
        "${nativeModsDir}/BG3NativeCameraTweaks.dll" = {
          source = "${modSrc}/bin/NativeMods/BG3NativeCameraTweaks.dll";
        };
      })

      (mkIf (cameraTweaks.enable && cameraTweaks.settings != {}) {
        "${nativeModsDir}/BG3NativeCameraTweaks.toml" = {
          source = tomlFormat.generate "BG3NativeCameraTweaks.toml" cameraTweaks.settings;
        };
      })
    ];
  };
}
