{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types mkOption mkIf mkMerge;

  sources = import ./npins;
  cfg = config.user.gaming.bg3;
  steamPath = lib.removePrefix "${config.user.homeDirectory}/" config.user.paths.steam.path;
  bg3Bin = "${steamPath}/steamapps/common/Baldurs Gate 3/bin";
  nativeModsDir = "${bg3Bin}/NativeMods";

  tomlFormat = pkgs.formats.toml {};

  bg3seVersion = sources.bg3se.version;
  bg3seDate = lib.removePrefix "updater-" bg3seVersion;
in {
  options.user.gaming.bg3 = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Baldur's Gate 3 mod management";
    };

    scriptExtender = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install BG3 Script Extender (DWrite.dll auto-updater)";
      };
    };

    nativeModLoader = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Install NativeModLoader (bink2w64.dll proxy).
          Required for WASD and NativeCameraTweaks.
          Back up the original bin/bink2w64.dll to bin/bink2w64_original.dll before enabling.
        '';
      };
      source = mkOption {
        type = types.path;
        description = "Path to NativeModLoader's bink2w64.dll (download from Nexus Mods)";
      };
    };

    wasd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install WASD character movement mod";
      };
      source = mkOption {
        type = types.path;
        description = "Path to BG3WASD.dll (download from Nexus Mods)";
      };
      settings = mkOption {
        type = tomlFormat.type;
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
      source = mkOption {
        type = types.path;
        description = "Path to BG3NativeCameraTweaks.dll (download from Nexus Mods)";
      };
      settings = mkOption {
        type = tomlFormat.type;
        default = {};
        description = "BG3NativeCameraTweaks TOML configuration settings";
      };
    };
  };

  config = mkIf cfg.enable {
    bayt.users."${config.user.name}".files = mkMerge [
      (mkIf cfg.scriptExtender.enable {
        "${bg3Bin}/DWrite.dll" = {
          clobber = true;
          source = "${pkgs.fetchzip {
            url = "https://github.com/Norbyte/bg3se/releases/download/${bg3seVersion}/BG3SE-Updater-${bg3seDate}.zip";
            sha256 = "sha256-rLD8rgUz3ppj/SMzZUMoqzJFeBEHWMsjrXYi3vPvR2o=";
            stripRoot = false;
          }}/DWrite.dll";
        };
      })

      (mkIf cfg.nativeModLoader.enable {
        "${bg3Bin}/bink2w64.dll" = {
          clobber = true;
          source = cfg.nativeModLoader.source;
        };
      })

      (mkIf cfg.wasd.enable {
        "${nativeModsDir}/BG3WASD.dll" = {
          clobber = true;
          source = cfg.wasd.source;
        };
        "${nativeModsDir}/BG3WASD.toml" = {
          clobber = true;
          source = tomlFormat.generate "BG3WASD.toml" cfg.wasd.settings;
        };
      })

      (mkIf cfg.nativeCameraTweaks.enable {
        "${nativeModsDir}/BG3NativeCameraTweaks.dll" = {
          clobber = true;
          source = cfg.nativeCameraTweaks.source;
        };
      })

      (mkIf (cfg.nativeCameraTweaks.enable && cfg.nativeCameraTweaks.settings != {}) {
        "${nativeModsDir}/BG3NativeCameraTweaks.toml" = {
          clobber = true;
          source = tomlFormat.generate "BG3NativeCameraTweaks.toml" cfg.nativeCameraTweaks.settings;
        };
      })
    ];
  };
}
