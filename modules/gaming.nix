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
}: {
  config = lib.mkIf (builtins.elem "gaming" profile.features) {
    home.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];

    # Define paths as Nix variables
    home.activation.symlinkGameConfigFiles = let
      # Base directories
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
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Marvel Rivals directories
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrGameDir}/Content/Paks/~mods/"
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Config/Windows/"
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${mrCompatDir}/Saved/Saved/Config/"

        # Wukong directory
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${wkCompatDir}/Saved/Config/Windows/"

        # Marvel Rivals symlinks
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/GameUserSettings.ini" "${mrCompatDir}/Saved/Config/Windows/GameUserSettings.ini"
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/Engine.ini" "${mrCompatDir}/Saved/Config/Windows/Engine.ini"

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

        $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${mrConfigDir}/zPochitaJeff_9999999_P.pak" "${mrGameDir}/Content/Paks/~mods/zPochitaJeff_9999999_P.pak"

        # Wukong symlink
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG "${wkConfigDir}/Engine.ini" "${wkCompatDir}/Saved/Config/Windows/Engine.ini"
      '';
  };
}
