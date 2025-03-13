#================================================================================
#                                modules/gaming.nix
#      🎮 Gaming Configuration
#================================================================================
# 🎯 Steam settings
# 🎮 Gaming packages
# 🔧 Performance tweaks
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Fine-grained configuration toggles
  gameConfig = {
    # Marvel Rivals configuration
    marvelRivals = {
      enabled = true; # Master toggle for Marvel Rivals
      engineIni = true; # Engine.ini configuration
      gameUserSettings = true; # GameUserSettings.ini configuration
      marvelUserSettings = true; # MarvelUserSettings.ini for profiles
      mods = false; # Game mods in ~mods directory
    };

    # Wukong configuration
    wukong = {
      enabled = true; # Master toggle for Wukong
      engineIni = true; # Engine.ini configuration
    };
  };

  # Package configuration
  packages = {
    base = {
      steam = true;
      protonup = true;
      gamemode = true;
      protontricks = true;
    };
    optional = {
      prismlauncher = true; # Minecraft launcher
    };
  };

  # Define paths as Nix variables
  configDir = "${config.home.homeDirectory}/nixos/pkg/gaming-config";
  steamDir = "$HOME/.local/share/Steam";

  # Marvel Rivals paths
  mrConfigDir = "${configDir}/marvel-rivals";
  mrSteamId = "2767030";
  mrCompatDir = "${steamDir}/steamapps/compatdata/${mrSteamId}/pfx/drive_c/users/steamuser/AppData/Local/Marvel";
  mrGameDir = "${steamDir}/steamapps/common/MarvelRivals/MarvelGame/Marvel";

  # Wukong paths
  wkConfigDir = "${configDir}/wukong";
  wkSteamId = "2358720";
  wkCompatDir = "${steamDir}/steamapps/compatdata/${wkSteamId}/pfx/drive_c/users/steamuser/AppData/Local/b1";
in {
  config = lib.mkIf (builtins.elem "gaming" profile.features) {
    home.packages = with pkgs; (
      (
        if packages.base.steam
        then [steam]
        else []
      )
      ++ (
        if packages.base.protonup
        then [protonup-qt]
        else []
      )
      ++ (
        if packages.base.gamemode
        then [gamemode]
        else []
      )
      ++ (
        if packages.base.protontricks
        then [protontricks]
        else []
      )
      ++ (
        if packages.optional.prismlauncher
        then [prismlauncher]
        else []
      )
    );

    home.activation.symlinkGameConfigFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.optionalString gameConfig.marvelRivals.enabled ''
        # Marvel Rivals base directories
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Config/Windows/"
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Saved/Config/"
        ${lib.optionalString gameConfig.marvelRivals.mods ''
          # Marvel Rivals mods directory
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrGameDir}/Content/Paks/~mods/"

          # Symlink all mod files from the ~mods directory
          for modfile in $(find "${mrConfigDir}/~mods/" -type f 2>/dev/null); do
            filename=$(basename "$modfile")
            $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$modfile" "${mrGameDir}/Content/Paks/~mods/$filename"
          done
        ''}

        ${lib.optionalString gameConfig.marvelRivals.engineIni ''
          # Marvel Rivals Engine.ini
          $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/Engine.ini" "${mrCompatDir}/Saved/Config/Windows/Engine.ini"
        ''}

        ${lib.optionalString gameConfig.marvelRivals.gameUserSettings ''
          # Marvel Rivals GameUserSettings.ini
          $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/GameUserSettings.ini" "${mrCompatDir}/Saved/Config/Windows/GameUserSettings.ini"
        ''}

        ${lib.optionalString gameConfig.marvelRivals.marvelUserSettings ''
          # Find and symlink to all profile directories
          for dir in $(find "${mrCompatDir}/Saved/Saved/Config/" -type d -not -path "*/\.*" 2>/dev/null || echo "${mrCompatDir}/Saved/Saved/Config/"); do
            if [[ "$dir" != "${mrCompatDir}/Saved/Saved/Config/" ]]; then
              $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$dir"
              $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/MarvelUserSettings.ini" "$dir/MarvelUserSetting.ini"
            fi
          done

          # Create default profile directories if none exist
          if [ -z "$(ls -A "${mrCompatDir}/Saved/Saved/Config/" 2>/dev/null)" ]; then
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Saved/Config/default/"
            $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/MarvelUserSettings.ini" "${mrCompatDir}/Saved/Saved/Config/default/MarvelUserSetting.ini"
          fi
        ''}
      ''}

      ${lib.optionalString gameConfig.wukong.enabled ''
        # Wukong directory
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${wkCompatDir}/Saved/Config/Windows/"

        ${lib.optionalString gameConfig.wukong.engineIni ''
          # Wukong Engine.ini
          $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${wkConfigDir}/Engine.ini" "${wkCompatDir}/Saved/Config/Windows/Engine.ini"
        ''}
      ''}
    '';
  };
}
